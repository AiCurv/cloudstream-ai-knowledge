# AI Agent Usage Guide

## QUICK START (for AI agents)

1. Read `agent-index.json` first - machine-readable, fastest lookup
2. Read `ERRORS_DB.md` when encountering build/runtime errors
3. Read `SITE_PATTERNS.md` when scraping a new site
4. Read `KNOWLEDGE_BASE.md` for complete code templates

## WORKFLOW

```
Task: Build Cloudstream extension for site X
  |
  v
1. Read agent-index.json -> get critical versions, known gotchas
  |
  v
2. Check site X for Cloudflare (incognito browser test)
  |-> Cloudflare YES -> tell user to pick different site. STOP.
  |-> Cloudflare NO  -> continue
  |
  v
3. Scrape site X homepage -> identify video card selectors
  |
  v
4. Test search URL pattern -> test multi-word encoding (dashes vs + vs %20)
  |
  v
5. Scrape video page -> find MP4 source tags, title/poster/desc selectors
  |
  v
6. Build extension using KNOWLEDGE_BASE.md templates
  |
  v
7. If build error -> look up in ERRORS_DB.md or agent-index.json errors_quick
  |
  v
8. Push to GitHub -> CI builds .cs3 -> user installs
```

## CONTRIBUTING NEW KNOWLEDGE

When you (an AI agent) encounter a new error or pattern:

### Option A: Direct commit (if you have repo access)
1. Add error to `ERRORS_DB.md` following the format
2. Add pattern to `SITE_PATTERNS.md` if new site
3. Update `agent-index.json` errors_quick or relevant section
4. Increment meta.version in agent-index.json
5. Commit with message: "agent-update: [description]"

### Option B: GitHub Issue (for external agents)
1. Open issue on AiCurv/cloudstream-ai-knowledge
2. Title: "ERROR #[next_number]: [symptom]"
3. Body: Follow ERRORS_DB.md format
4. Label: "error-report" or "site-pattern"

## FILE PRIORITY (read order)

| Priority | File | When to Read |
|----------|------|-------------|
| 0 | AI_AGENT_PROMPT.md | ACTIVATION — read this first if you are an AI agent being activated |
| 1 | agent-index.json | ALWAYS first - fast lookup |
| 2 | ERRORS_DB.md | On any build/runtime error |
| 3 | SITE_PATTERNS.md | When analyzing a new site |
| 4 | KNOWLEDGE_BASE.md | When writing code from scratch |

## COMMON MISTAKES TO AVOID

1. Using URLEncoder for search URLs → use dashes instead
2. Setting JVM target to 17 → must be 1.8
3. Using Kotlin 2.1.0 → must be 2.3.0
4. Forgetting tvTypes = listOf("NSFW") for adult content
5. Using addActors() → use this.actors = ...
6. Using "\s+" in regular Kotlin strings → use Regex("\\s+")
7. Writing CSS selectors via bash heredoc → use Python
8. Trying to bypass Cloudflare → pick a different site
9. Not testing multi-word search → ALWAYS test
10. Not incrementing version number → Cloudstream won't update
11. Not updating knowledge base after finding new errors → knowledge base becomes stale
12. Not testing M3U8 extraction before declaring loadLinks works → always verify video plays
