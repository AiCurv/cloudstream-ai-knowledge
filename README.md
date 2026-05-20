# Cloudstream AI Agent Knowledge Base

A machine-optimized knowledge base for AI agents building Cloudstream extensions. Born from real production errors, real fixes, real attempts that failed.

## What Is This?

This repo is a database of everything an AI agent needs to build working Cloudstream extensions from scratch. Every error, every fix, every site pattern, every gotcha — structured for instant machine consumption, not casual human reading.

**For AI agents:** Read `agent-index.json` first, then drill into specific files as needed.

**For humans:** You don't read this. You give this to your AI agent along with a target website, and the agent builds the extension.

## Quick Start (For Humans)

### The 2-Step Workflow

1. **Give your AI agent this prompt + the knowledge base URL**
2. **Tell it which website to build an extension for**

That's it. Your AI agent will:
- Read the knowledge base
- Analyze the target website
- Build the extension
- Handle all the common errors automatically
- Update the knowledge base with any new errors it discovers

### Copy This Prompt

Open [AI_AGENT_PROMPT.md](./AI_AGENT_PROMPT.md), copy the entire content, and paste it to your AI agent. Then just say the website you want.

Example:
```
[paste the entire AI_AGENT_PROMPT.md content here]

Target website: https://example.com
```

## Repository Structure

| File | Purpose | Read By |
|------|---------|---------|
| `agent-index.json` | Machine-readable quick reference — versions, error lookups, mappings | AI agents (read FIRST) |
| `KNOWLEDGE_BASE.md` | Complete code templates — root build, provider build, Plugin.kt, Provider.kt, CI/CD | AI agents (when writing code) |
| `ERRORS_DB.md` | Every error encountered with symptom/cause/fix/failed attempts | AI agents (on build errors) |
| `SITE_PATTERNS.md` | Site scraping patterns — selectors, URL patterns, extraction methods | AI agents (when analyzing new sites) |
| `AGENT_GUIDE.md` | Workflow guide — step-by-step process for building extensions | AI agents (quick reference) |
| `AI_AGENT_PROMPT.md` | Universal prompt template — copy this to activate any AI agent | Humans (copy and give to agent) |
| `update.sh` | Auto-update script — increments version, commits, pushes | AI agents (after adding new knowledge) |

## How It Works

```
Human: "Build extension for site X"
         |
         v
AI Agent reads agent-index.json ---------> Gets critical versions & known gotchas
         |
         v
AI Agent checks site X for Cloudflare ----> Blocked? Tell user. Not blocked? Continue.
         |
         v
AI Agent scrapes site X ------------------> Uses SITE_PATTERNS.md to analyze structure
         |
         v
AI Agent builds extension ----------------> Uses KNOWLEDGE_BASE.md templates
         |
         v
Build error? -----------------------------> Looks up in ERRORS_DB.md, applies fix
         |
         v
Push to GitHub ---------------------------> CI builds .cs3, user installs
         |
         v
New error found? -------------------------> Agent updates this knowledge base
```

## Contributing

### For AI Agents (Automatic)
When you encounter a new error or discover a new site pattern:
1. Add the error to `ERRORS_DB.md` following the existing format
2. Add site patterns to `SITE_PATTERNS.md` if it's a new site
3. Update `agent-index.json` with the new quick-lookup entry
4. Run `./update.sh "description of change"`

### For Humans (Manual)
1. Fork this repo
2. Add your error/pattern following the existing format
3. Open a Pull Request
4. Or open a GitHub Issue with label `error-report` or `site-pattern`

## Error Categories Covered

- Build errors (Kotlin version, JVM target, unresolved references)
- Gradle configuration (plugin application, dependency resolution)
- GitHub Actions CI/CD (permissions, branch pushing)
- Search functionality (URL encoding, multi-word queries)
- App behavior (tvTypes, caching, tag limitations)
- Site scraping (Cloudflare, CSS selectors, lazy images)
- Code generation (bracket corruption in shell, regex escaping)
- API limitations (stubs missing methods, display-only features)

## Stats

- **Errors documented:** 12
- **Site patterns:** 3 (1 specific + 2 generic)
- **Knowledge base version:** 2.0
- **Last updated:** 2026-05-20

## License

MIT — Use it, share it, improve it.
