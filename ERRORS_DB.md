# Cloudstream Extension Errors Database

## FORMAT
```
### ERROR #[id]
- **symptom**: what you see
- **cause**: root cause
- **fix**: exact fix
- **attempts_failed**: what was tried and failed
- **discovered_in**: repo/commit context
```

---

### ERROR #1 - Unresolved reference 'Plugin'
- **symptom**: `e: Unresolved reference 'Plugin'` in Plugin.kt
- **cause**: Missing `apply(plugin = "com.lagradost.cloudstream3.gradle")` and `cloudstream("com.lagradost:cloudstream3:pre-release")` dependency
- **fix**: Add cloudstream gradle plugin to subprojects AND add pre-release stubs dependency:
  ```kotlin
  subprojects {
      apply(plugin = "com.lagradost.cloudstream3.gradle")  // REQUIRED
      dependencies {
          val cloudstream by configurations
          cloudstream("com.lagradost:cloudstream3:pre-release")  // REQUIRED for Plugin, MainAPI stubs
      }
  }
  ```
- **attempts_failed**: Adding individual import statements (the classes simply don't exist without stubs)
- **discovered_in**: AiCurv/aicurv initial build

---

### ERROR #2 - Kotlin version mismatch (2.1.0 vs 2.3.0)
- **symptom**: `Some Kotlin metadata version mismatch. Expected 2.3, got 2.1`
- **cause**: Kotlin gradle plugin version must be 2.3.0 because pre-release stubs were compiled with 2.3.0
- **fix**: Use `classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.0")` explicitly
- **attempts_failed**: Using default Kotlin version from Android Gradle Plugin (too new, 2.1.x)
- **discovered_in**: AiCurv/aicurv XXDBXProvider

---

### ERROR #3 - JVM target 1.8 vs 17
- **symptom**: `Unsupported class file major version 17` or similar class version errors
- **cause**: JVM target must be 1.8 not 17. Cloudstream extensions run on Android JVM 1.8 compatibility
- **fix**: In `tasks.withType<KotlinJvmCompile>`, set `jvmTarget.set(JvmTarget.JVM_1_8)`
- **attempts_failed**: Using JVM_17 or JVM_21
- **discovered_in**: AiCurv/aicurv CI build

---

### ERROR #4 - GitHub Actions 403 permission denied on push to builds branch
- **symptom**: `remote: Permission to AiCurv/aicurv.git denied to github-actions[bot]`
- **cause**: Missing `permissions: contents: write` in workflow YAML
- **fix**:
  ```yaml
  name: Build
  permissions:
    contents: write  # REQUIRED for pushing to builds branch
  ```
- **attempts_failed**: PAT tokens, different checkout actions - the workflow simply lacks write permission by default
- **discovered_in**: AiCurv/aicurv CI/CD

---

### ERROR #5 - Search returns 0 results for multi-word queries
- **symptom**: Single word search works, multi-word returns empty. "hot" works, "hot asian" returns nothing
- **cause**: `java.net.URLEncoder.encode()` converts spaces to `+` signs. Many sites (especially xxdbx.com) treat `+` as literal text in URL path segments, not as space encoding. The `+` encoding only works in query parameters (`?q=hot+asian`), NOT in path segments (`/search/hot+asian`)
- **fix**: Replace spaces with dashes for path-segment search URLs:
  ```kotlin
  val searchQuery = query.trim()
      .replace(" ", "-")
      .replace(Regex("\\s+"), "-")
  val searchUrl = "$mainUrl/search/$searchQuery"
  ```
- **attempts_failed**:
  - URLEncoder.encode() with + signs → 0 results
  - URLEncoder.encode() with %20 → site returns different results
  - Raw spaces in URL → malformed URL
- **tested_working**:
  - xxdbx.com/search/hot-asian-teen → 75 results ✓
  - xxdbx.com/search/Kwini-Kim → 38 results ✓
  - xxdbx.com/search/hot+asian+teen → 0 results ✗
  - xxdbx.com/search/hot%20asian%20teen → works but dashes are more reliable
- **discovered_in**: AiCurv/aicurv XXDBXProvider

---

### ERROR #6 - tvTypes not taking effect, extension appears under Movies instead of NSFW
- **symptom**: Extension shows in Movies category, no 18+/NSFW tag, no adult content flag
- **cause**: Multiple factors:
  1. `tvTypes` must be set in provider `build.gradle.kts` cloudstream block: `tvTypes = listOf("NSFW")`
  2. `supportedTypes = setOf(TvType.NSFW)` must be in Provider class
  3. User must enable "Show 18+ content" in Cloudstream settings
  4. Old extension must be uninstalled first (cached metadata)
- **fix**:
  ```kotlin
  // build.gradle.kts:
  cloudstream {
      tvTypes = listOf("NSFW")  // THIS determines app category
  }
  // Provider.kt:
  override val supportedTypes = setOf(TvType.NSFW)  // THIS determines search filter
  ```
- **attempts_failed**:
  - Setting tvTypes = listOf("Movie") then changing → cached on device
  - Only setting supportedTypes without tvTypes → still shows as Movie
  - Adding both but not uninstalling old extension → shows old metadata
- **discovered_in**: AiCurv/aicurv HDPornFull → XXDBX migration

---

### ERROR #7 - Unsupported escape sequence in Kotlin string
- **symptom**: `e: Unsupported escape sequence` on line with regex `\\s+`
- **cause**: Kotlin string literals don't support `\\s` as an escape. `\\s` is a regex metacharacter, not a Kotlin string escape. In regular strings, use `\\\\s+`. In raw strings, `\\s+` works.
- **fix**:
  ```kotlin
  // WRONG:
  .replace("\\s+".toRegex(), "-")  // Compile error

  // CORRECT option 1:
  .replace(Regex("\\\\s+"), "-")
  // CORRECT option 2:
  .replace("\\\\s+".toRegex(), "-")

  // CORRECT option 3 (simple, catches 99% of cases):
  .replace(" ", "-")
  ```
- **attempts_failed**: `"\\s+".toRegex()` → compile error
- **discovered_in**: AiCurv/aicurv XXDBXProvider V2.5 build

---

### ERROR #8 - Unresolved reference 'addActors'
- **symptom**: `e: Unresolved reference 'addActors'` in load() function
- **cause**: `addActors()` helper function does NOT exist in pre-release stubs. It was removed or never added.
- **fix**:
  ```kotlin
  // WRONG:
  addActors(actors)

  // CORRECT:
  return newMovieLoadResponse(title, url, TvType.NSFW, url) {
      this.actors = actors  // Direct property assignment
  }
  ```
- **attempts_failed**: `addActors()`, `addActor()` - neither exists in pre-release stubs
- **discovered_in**: AiCurv/aicurv XXDBXProvider V2.5 build

---

### ERROR #9 - Cloudflare-protected sites return challenge pages
- **symptom**: app.get() returns Cloudflare challenge HTML instead of actual page content. Search returns 0 results, homepage empty.
- **cause**: Site uses Cloudflare bot protection. Cloudstream's NiceHttp doesn't handle Cloudflare JS challenges by default.
- **fix**: DO NOT use Cloudflare-protected sites. Switch to sites without bot protection.
  - Test: Open site in incognito browser. If you see "Checking your browser" → Cloudflare protected → AVOID
  - Alternative: Use `vpnStatus = VPNStatus.MightBeNeeded` and hope the user's IP passes, but this is unreliable
- **attempts_failed**:
  - WebViewResolver (wrong API, doesn't exist in stubs)
  - Custom headers (doesn't bypass Cloudflare JS challenge)
  - Cookie-based approaches (Cloudflare requires JS execution)
  - Various referer/user-agent tricks (none bypass modern Cloudflare)
- **discovered_in**: HDPornFull (hdpornfull.com) → abandoned for xxdbx.com

---

### ERROR #10 - CSS selectors with brackets corrupted when writing files
- **symptom**: `a[href*=/view/]` becomes `aref*=/view/]` in the written file. The `[href` portion is stripped.
- **cause**: Shell/bash interprets `[href` as a glob pattern or the terminal renders `[` as ANSI escape sequence start. When writing Kotlin files via bash heredocs, bracket sequences can be mangled.
- **fix**: Write files using Python instead of bash heredocs:
  ```python
  # Python approach - brackets are preserved correctly
  content = 'val a = element.selectFirst("a' + '[' + 'href*=/view/]")'
  with open('Provider.kt', 'w') as f:
      f.write(content)
  ```
  Always verify file contents after writing by checking raw bytes:
  ```python
  with open('Provider.kt', 'rb') as f:
      idx = f.read().find(b'view')
      print(f.read()[idx-30:idx+30])  # Check actual bytes around selector
  ```
- **attempts_failed**:
  - Bash heredoc with 'EOF' quoting → still corrupts
  - Direct Write tool → sometimes corrupts bracket sequences
  - Echo with escaping → inconsistent
- **discovered_in**: AiCurv/aicurv XXDBXProvider file writing

---

### ERROR #11 - getMainPage returns empty, no categories shown
- **symptom**: Extension opens but shows no content/categories
- **cause**: Missing `hasMainPage = true` override AND/OR `getMainPage()` not implemented AND/OR wrong CSS selectors
- **fix**:
  ```kotlin
  override val hasMainPage = true  // REQUIRED

  override val mainPage = mainPageOf(
      "$mainUrl/" to "Category Name",  // URL -> display name pairs
  )

  override suspend fun getMainPage(page: Int, request: MainPageRequest): HomePageResponse {
      val url = if (page > 1) "${request.data}?page=$page" else request.data
      val document = app.get(url).document
      val videos = document.select("CORRECT_SELECTOR").mapNotNull { ... }
      return newHomePageResponse(listOf(HomePageList(request.name, videos)), hasNextPage)
  }
  ```
- **attempts_failed**:
  - Setting hasMainPage = true without getMainPage → empty
  - Wrong selectors (WordPress selectors on non-WordPress site) → empty
  - Not returning HomePageResponse correctly → crash
- **discovered_in**: AiCurv/aicurv HDPornFull empty homepage

---

### ERROR #12 - Old extension cached on device after repo update
- **symptom**: Updated extension in repo but user still sees old name, old behavior, old tvTypes
- **cause**: Cloudstream caches extension metadata. Old .cs3 file stays installed until manually removed.
- **fix**: User MUST:
  1. Uninstall old extension from Cloudstream → Settings → Extensions
  2. Remove the repository from Cloudstream
  3. Re-add repository URL
  4. Install fresh extension
  No code fix possible - this is app behavior.
- **discovered_in**: AiCurv/aicurv HDPornFull → XXDBX migration

---

### ERROR #13 - SearchResponse is interface, cannot instantiate directly
- **symptom**: `e: Interface 'interface SearchResponse : Any' does not have constructors` when trying `SearchResponse(...)`
- **cause**: `SearchResponse` is an interface, not a data class. Must use factory method `newMovieSearchResponse(...)` instead.
- **fix**: Use `newMovieSearchResponse(name, url, type) { posterUrl = ... }` - never instantiate SearchResponse directly
- **attempts_failed**: Direct instantiation like `MovieSearchResponse(...)`
- **discovered_in**: AiCurv/cloudstream-extensions XHamsterProvider build

---

### ERROR #14 - MovieLoadResponse deprecated constructor requires apiName
- **symptom**: `e: No value passed for parameter 'apiName'` when using `MovieLoadResponse(...)` constructor directly
- **cause**: The old `MovieLoadResponse(name, url, apiName, type, dataUrl, ...)` constructor is deprecated. Use `newMovieLoadResponse()` factory method instead.
- **fix**: Use `newMovieLoadResponse(name, url, type, dataUrl) { this.posterUrl = ...; this.plot = ... }` DSL-style builder
- **attempts_failed**: Using direct constructor with all positional args
- **discovered_in**: AiCurv/cloudstream-extensions XHamsterProvider build

---

### ERROR #15 - Jackson readValue String parameter not available
- **symptom**: `e: Argument type mismatch: actual type is 'String', but 'Reader!' was expected` when using `jacksonMapper.readValue(jsonString)`
- **cause**: Jackson's `readValue(String)` overload is not available in the Kotlin jackson-module-kotlin setup. Must use `TypeReference` or `JavaType`.
- **fix**:
  ```kotlin
  // WRONG:
  jacksonMapper.readValue<Map<String, Any>>(jsonStr)

  // CORRECT:
  jacksonMapper.readValue(jsonStr, object : TypeReference<Map<String, Any>>() {})
  ```
- **attempts_failed**: Using plain `readValue<T>(String)` directly
- **discovered_in**: AiCurv/cloudstream-extensions XHamsterProvider build

---

### ERROR #16 - Gradle wrapper not present - CI fails with "gradlew not found"
- **symptom**: `chmod: cannot access 'gradlew': No such file or directory` in CI
- **cause**: Gradle wrapper files (`gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.properties`, `gradle/wrapper/gradle-wrapper.jar`) were not committed to git
- **fix**: Run `gradle wrapper --gradle-version=8.9` locally and commit all generated wrapper files. Note: Android Gradle Plugin 8.7.3 requires Gradle 8.9 minimum.
- **attempts_failed**: Trying to download gradle in CI, using wrong gradle version
- **discovered_in**: AiCurv/cloudstream-extensions CI build

---

### ERROR #17 - newMovieSearchResponse named parameter 'posterUrl' not found
- **symptom**: `e: No parameter with name 'posterUrl' found` when using `newMovieSearchResponse(..., posterUrl = ...)`
- **cause**: The DSL block style `newMovieSearchResponse(...) { posterUrl = ... }` uses different parameter names inside the block vs constructor. Inside the block, use `posterUrl` as a property assignment, not as a named constructor arg.
- **fix**:
  ```kotlin
  // CORRECT - DSL block style:
  newMovieSearchResponse(name, url, type) {
      this.posterUrl = posterUrlHere
      this.year = yearHere
  }
  ```
- **attempts_failed**: `newMovieSearchResponse(name, url, type, posterUrl = ...)` positional args
- **discovered_in**: AiCurv/cloudstream-extensions XHamsterProvider build

---

### ERROR #18 - Cloudstream gradle plugin requires Gradle 8.9+
- **symptom**: `Minimum supported Gradle version is 8.9. Current version is 8.7`
- **cause**: Android Gradle Plugin 8.7.3 and Cloudstream gradle plugin require Gradle 8.9 minimum
- **fix**: Use `gradle wrapper --gradle-version=8.9` to generate wrapper with 8.9
- **attempts_failed**: Using Gradle 8.7 which was previously default
- **discovered_in**: AiCurv/cloudstream-extensions XHamsterProvider build