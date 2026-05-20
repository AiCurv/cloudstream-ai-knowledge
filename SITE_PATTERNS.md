# Site Scraping Patterns for Cloudstream Extensions

## FORMAT
```
### SITE: domain.com
- type: site category (tube/aggregator/embed)
- cloudflare: yes/no
- search_url: pattern
- search_encoding: how spaces are encoded
- video_card: CSS selector for video listing items
- video_page: URL pattern for individual videos
- mp4_method: direct/iframe/m3u8
- pagination: pattern
- selectors: { key CSS selectors }
```

---

### SITE: xxdbx.com
- **type**: tube (direct MP4 hosting)
- **cloudflare**: NO
- **search_url**: `https://xxdbx.com/search/{query}`
- **search_encoding**: DASHES (spaces → `-`). Plus signs return 0 results. %20 works but dashes preferred.
- **video_card**: `div.v`
  - link: `a[href*=/view/]` attr `abs:href`
  - title: `div.v_title` text
  - thumbnail: `img.v_pic` attr `data-src` fallback `src`
  - duration: `div.v_dur` text
  - preview: `div.v_preview` attr `data-preview` (mp4 preview clip)
- **video_page**: `https://xxdbx.com/view/{id}`
- **mp4_method**: DIRECT. `<video><source src="//d.v1d30.com/.../360.mp4" title="360p">`
  - Multiple qualities: 360p, 720p, 1080p
  - Source URLs start with `//` → prefix `https:`
- **categories**:
  - Newest: `/`
  - Most Popular: `/most-popular`
  - Tag search: `/search/{tag}` (e.g. `/search/MILF`, `/search/big-tits`)
  - Stars: `/stars/{name}` (e.g. `/stars/Kwini%20Kim`) - same HTML structure as search
  - Channels: `/channels/{name}` (e.g. `/channels/LegalPorno.com`) - same HTML structure
- **pagination**: `?page=2`, `?page=3` etc. Pagination element: `div.pagina` with `a[href*=page=N]`
- **video_detail_selectors**:
  - title: `article h1`
  - poster: `video[poster]` attr `poster`
  - description: `#desc`
  - tags: `div.tags a[href*=/search/]`
  - stars/actors: `div.tags a[href*=/stars/]`
  - channel: `div.tags a[href*=/channels/]`
  - date: `div.tags a[href*=/dates/]`
- **lazy_images**: Some `img.v_pic` have `class="lazy"` with `data-src` instead of `src`. Always check data-src first.
- **tested**: 2026-05-20, all features working

---

### GENERIC PATTERN: WordPress-based adult sites
- **video_card**: `article.post`, `.entry`, `.post-item`
  - link: `h2 a, h3 a, .entry-title a`
  - thumbnail: `img` with `data-src` or `data-lazy-src`
- **mp4_method**: Usually iframe embed (not direct MP4)
- **search_url**: `?s={query}` (query parameter, not path segment)
- **cloudflare**: OFTEN YES - check before committing
- **warning**: WordPress sites frequently have Cloudflare. Test first.

---

### GENERIC PATTERN: Tube sites with direct MP4
- **video_card**: Common patterns: `.video-item`, `.thumb`, `.video-thumb`
- **mp4_method**: `<video><source src="..." title="720p">` or `<source>` tags
- **search_url**: Usually `/search/{query}` or `/search?q={query}`
- **quality_labels**: 360p, 480p, 720p, 1080p in `title` or `data-quality` attr

---

## HOW TO ANALYZE A NEW SITE

### Step 1: Check Cloudflare
- Open site in incognito browser
- If "Checking your browser" challenge appears → AVOID, find alternative

### Step 2: Identify HTML structure
- Use page_reader or curl to fetch homepage HTML
- Find video card pattern: look for repeating `div` with thumbnail + title + link
- Find pagination: look for `page=2`, `/page/2/`, `?p=2` etc

### Step 3: Test search
- Try `/search/query` first (most common)
- Try `?s=query` (WordPress)
- Test with multi-word: try dashes, %20, + to see which works
- Check if `/search/` and `/stars/` return same HTML structure

### Step 4: Analyze video page
- Find `<video>` and `<source>` tags for direct MP4
- Find `<iframe>` for embedded players
- Find title, poster, description, tags selectors

### Step 5: Extract MP4 sources
- Direct MP4: `document.select("video source")` → `attr("src")` + `attr("title")`
- Iframe embeds: `document.select("iframe[src]")` → `loadExtractor()`
- M3U8 streams: Check for `.m3u8` URLs, use `ExtractorLinkType.M3U8`

### Step 6: Build categories
- Homepage categories from site navigation
- Tag-based categories from popular search terms
- Channel/studio categories from site's channel pages
- Star/actor categories from site's star pages
