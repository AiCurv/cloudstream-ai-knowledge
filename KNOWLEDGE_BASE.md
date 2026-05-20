# Cloudstream Extension AI Agent Knowledge Base

## METADATA
- version: 2.0
- last_updated: 2026-05-20
- source: real production errors from AiCurv/aicurv repo builds
- consumers: AI agents building Cloudstream extensions

## ARCHITECTURE

```
repo-root/
  build.gradle.kts         # root: kotlin 2.3.0, JVM 1.8, cloudstream gradle plugin
  settings.gradle.kts       # auto-discovers subdirs with build.gradle.kts
  repo.json                 # -> builds/plugins.json
  gradle.properties
  .github/workflows/build.yml
  ProviderDir/
    build.gradle.kts        # version, tvTypes, cloudstream{description,authors,status}
    src/main/kotlin/pkg/
      Plugin.kt             # @CloudstreamPlugin, registerMainAPI()
      Provider.kt           # MainAPI subclass
  builds/                   # CI output: .cs3 + plugins.json
```

## ROOT build.gradle.kts

```kotlin
import com.android.build.gradle.BaseExtension
import com.lagradost.cloudstream3.gradle.CloudstreamExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile

buildscript {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io")
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.3")
        classpath("com.github.recloudstream:gradle:-SNAPSHOT")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io")
    }
}

subprojects {
    apply(plugin = "com.android.library")
    apply(plugin = "kotlin-android")
    apply(plugin = "com.lagradost.cloudstream3.gradle")

    extensions.configure<CloudstreamExtension> {
        setRepo(System.getenv("GITHUB_REPOSITORY") ?: "User/repo")
    }

    extensions.configure<BaseExtension> {
        namespace = "com.providerpkg"
        defaultConfig {
            minSdk = 21
            compileSdkVersion(35)
            targetSdk = 35
        }
        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_1_8
            targetCompatibility = JavaVersion.VERSION_1_8
        }
    }

    tasks.withType<KotlinJvmCompile> {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_1_8)
            freeCompilerArgs.addAll(
                "-Xno-call-assertions",
                "-Xno-param-assertions",
                "-Xno-receiver-assertions"
            )
        }
    }

    dependencies {
        val cloudstream by configurations
        val implementation by configurations
        cloudstream("com.lagradost:cloudstream3:pre-release")
        implementation(kotlin("stdlib"))
        implementation("com.github.Blatzar:NiceHttp:0.4.11")
        implementation("org.jsoup:jsoup:1.18.3")
        implementation("com.fasterxml.jackson.module:jackson-module-kotlin:2.13.1")
    }
}

task("clean") { delete(rootProject.layout.buildDirectory) }
```

## PROVIDER build.gradle.kts

```kotlin
version = 1  // INTEGER ONLY. Increment on every code change.

cloudstream {
    description = "Name - short desc"
    authors = listOf("author")
    status = 1  // 0=Down 1=Ok 2=Slow 3=Beta-only
    tvTypes = listOf("NSFW")  // ADULT CONTENT: MUST be "NSFW" or appears under Movies
    requiresResources = false
    language = "en"
    iconUrl = "https://www.google.com/s2/favicons?domain=example.com&sz=%size%"
}
```

## Plugin.kt

```kotlin
package com.providerpkg
import android.content.Context
import com.lagradost.cloudstream3.plugins.CloudstreamPlugin
import com.lagradost.cloudstream3.plugins.Plugin

@CloudstreamPlugin
class ProviderPlugin : Plugin() {
    override fun load(context: Context) {
        registerMainAPI(Provider())
    }
}
```

## Provider.kt Full Template

```kotlin
package com.providerpkg
import com.lagradost.cloudstream3.*
import com.lagradost.cloudstream3.utils.*

class Provider : MainAPI() {
    override var mainUrl = "https://example.com"
    override var name = "Provider"
    override val supportedTypes = setOf(TvType.NSFW)
    override var lang = "en"
    override val hasMainPage = true
    override val hasDownloadSupport = true
    override val hasChromecastSupport = true

    override val mainPage = mainPageOf(
        "$mainUrl/" to "Newest",
        "$mainUrl/most-popular" to "Most Popular",
    )

    private fun String.fixUrl(): String = when {
        startsWith("//") -> "https:$this"
        startsWith("/") -> "$mainUrl$this"
        else -> this
    }

    override suspend fun getMainPage(page: Int, request: MainPageRequest): HomePageResponse {
        val url = if (page > 1) "${request.data}?page=$page" else request.data
        val doc = app.get(url).document
        val videos = doc.select("VIDEO_CARD_SELECTOR").mapNotNull { parseVideo(it) }
        val hasNext = doc.select("PAGINATION_NEXT_SELECTOR").first() != null
        return newHomePageResponse(listOf(HomePageList(request.name, videos)), hasNext)
    }

    override suspend fun search(query: String): List<SearchResponse> {
        val q = query.trim().replace(" ", "-")  // DASHES NOT PLUS. SEE ERRORS DB #5
        val doc = app.get("$mainUrl/search/$q").document
        return doc.select("VIDEO_CARD_SELECTOR").mapNotNull { parseVideo(it) }
    }

    override suspend fun load(url: String): LoadResponse {
        val doc = app.get(url).document
        val title = doc.selectFirst("h1")?.text()?.trim() ?: "Unknown"
        val poster = doc.selectFirst("video[poster]")?.attr("poster")?.fixUrl()
        val desc = doc.selectFirst(".desc")?.text()?.trim()
        val tags = doc.select("TAG_SELECTOR").mapNotNull { it.text()?.trim() }
        return newMovieLoadResponse(title, url, TvType.NSFW, url) {
            this.posterUrl = poster
            this.plot = desc
            this.tags = tags
        }
    }

    override suspend fun loadLinks(
        data: String, isCasting: Boolean,
        subtitleCallback: (SubtitleFile) -> Unit,
        callback: (ExtractorLink) -> Unit
    ): Boolean {
        val doc = app.get(data).document
        doc.select("video source").forEach { src ->
            val url = src.attr("src").fixUrl()
            val label = src.attr("title")
            if (url.isNotEmpty() && url.contains(".mp4")) {
                callback(ExtractorLink(
                    source = name, name = "$name $label", url = url,
                    referer = data,
                    quality = when(label) {
                        "1080p" -> Qualities.P1080.value
                        "720p" -> Qualities.P720.value
                        "480p" -> Qualities.P480.value
                        "360p" -> Qualities.P360.value
                        else -> Qualities.Unknown.value
                    },
                    type = ExtractorLinkType.VIDEO
                ))
            }
        }
        doc.select("iframe[src]").forEach {
            val s = it.attr("abs:src").ifEmpty { it.attr("src") }
            if (s.isNotEmpty()) loadExtractor(s.fixUrl(), data, subtitleCallback, callback)
        }
        return true
    }

    private fun parseVideo(el: org.jsoup.nodes.Element): SearchResponse? {
        val a = el.selectFirst("a[href*=/view/]") ?: return null
        val href = a.attr("abs:href").ifEmpty { a.attr("href") }.fixUrl()
        val title = el.selectFirst("div.v_title")?.text()?.trim() ?: return null
        val poster = el.selectFirst("img")?.let {
            it.attr("data-src").ifEmpty { it.attr("src") }
        }?.fixUrl()
        return newMovieSearchResponse(title, href, TvType.NSFW) { posterUrl = poster }
    }
}
```

## CI/CD build.yml

```yaml
name: Build
permissions:
  contents: write
concurrency:
  group: "build"
  cancel-in-progress: true
on:
  push:
    branches: [master, main]
    paths-ignore: ['*.md']
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@master
        with: { path: "src" }
      - uses: actions/checkout@master
        with: { ref: "builds", path: "builds" }
      - run: rm $GITHUB_WORKSPACE/builds/*.cs3 || true
      - uses: actions/setup-java@v1
        with: { java-version: 17 }
      - uses: android-actions/setup-android@v2
      - run: |
          cd $GITHUB_WORKSPACE/src
          chmod +x gradlew
          ./gradlew make makePluginsJson
          cp **/build/*.cs3 $GITHUB_WORKSPACE/builds
          cp build/plugins.json $GITHUB_WORKSPACE/builds
      - run: |
          cd $GITHUB_WORKSPACE/builds
          git config --local user.email "actions@github.com"
          git config --local user.name "GitHub Actions"
          git add .
          git commit --amend -m "Build $GITHUB_SHA" || exit 0
          git push --force
```

## repo.json

```json
{
  "name": "Repo Name",
  "description": "Desc",
  "manifestVersion": 1,
  "pluginLists": [
    "https://raw.githubusercontent.com/User/repo/builds/plugins.json"
  ]
}
```

## APP-LIMITED FEATURES

### Tags: DISPLAY ONLY, NOT CLICKABLE
Cloudstream ResultFragment.kt renders tags as Chip with:
```
chip.isClickable = false
chip.isFocusable = false
chip.isCheckable = false
```
NO click listener exists. Tags are pure display. WIP ITag/TagSelector API exists but unused.
WORKAROUND: Add tag-based URLs as mainPage categories instead.

### Search: string query only
`search(query: String)` takes one string. No tag callback, no filter API.
WORKAROUND: Map search queries to site-specific URL patterns.

### Actors: set via this.actors NOT addActors()
`addActors()` does NOT exist in pre-release stubs. Use:
```kotlin
this.actors = listOf(ActorData(Actor("name")))
```
