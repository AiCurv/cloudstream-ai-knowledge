#!/bin/bash
# Auto-update script for cloudstream-ai-knowledge
# Usage: ./update.sh "description of what was added/changed"
# AI agents: Run this after adding new errors, patterns, or fixes

set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

# Increment version in agent-index.json
python3 -c "
import json
with open('agent-index.json', 'r') as f:
    data = json.load(f)
v = float(data['meta']['version'])
data['meta']['version'] = str(round(v + 0.1, 1))
from datetime import datetime
data['meta']['updated'] = datetime.now().strftime('%Y-%m-%d')
with open('agent-index.json', 'w') as f:
    json.dump(data, f, indent=2)
print(f'Updated to version {data[\"meta\"][\"version\"]}')
"

MSG="${1:-agent-update: new knowledge added}"
git add -A
git commit -m "$MSG"
git push origin main 2>/dev/null || echo "Push failed - check remote access"
echo "Knowledge base updated and pushed."
