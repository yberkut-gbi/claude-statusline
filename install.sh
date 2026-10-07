#!/bin/bash
# Install the status line, its commands, and the statusLine setting into ~/.claude.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
dest="$HOME/.claude"
settings="$dest/settings.json"

command -v jq >/dev/null 2>&1 || { echo "Please install jq first (macOS: brew install jq)."; exit 1; }

mkdir -p "$dest/commands"
cp "$here/statusline.sh" "$dest/statusline.sh"
cp "$here/statusline-toggle.sh" "$dest/statusline-toggle.sh"
chmod +x "$dest/statusline.sh" "$dest/statusline-toggle.sh"
cp "$here"/commands/*.md "$dest/commands/"

[ -f "$settings" ] || echo '{}' > "$settings"
cp "$settings" "$settings.bak.$(date +%Y%m%d%H%M%S)"
tmp="$settings.tmp.$$"
jq --arg cmd "bash ~/.claude/statusline.sh" \
  '.statusLine = {type: "command", command: $cmd, refreshInterval: 1}' \
  "$settings" > "$tmp" && mv "$tmp" "$settings"

echo "Installed. Send a message in Claude Code to see the status line."
echo "Commands: /statusline-help, /statusline-toggle"
