#!/bin/sh
# Install the status line on macOS / Linux. Uses only POSIX sh, sed, awk.
# Windows: use install.ps1.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
dest="$HOME/.claude"
settings="$dest/settings.json"
run="sh ~/.claude/statusline.sh"

mkdir -p "$dest/commands"
cp "$here/src/statusline.sh" "$dest/statusline.sh"
cp "$here/commands/statusline-help.md" "$dest/commands/"
sed "s|{{TOGGLE_COMMAND}}|$run --toggle|" "$here/commands/statusline-toggle.md" > "$dest/commands/statusline-toggle.md"

# Set "statusLine" in settings.json: drop any old one, insert the new one after the first "{".
[ -f "$settings" ] || echo '{}' > "$settings"
cp "$settings" "$settings.bak.$(date +%Y%m%d%H%M%S)"
awk -v cmd="$run" '
  { s = s $0 "\n" }
  END {
    if (match(s, /"statusLine"[ \t\n]*:[ \t\n]*\{[^}]*\}[ \t\n]*,?/)) {
      pre = substr(s, 1, RSTART - 1); post = substr(s, RSTART + RLENGTH)
      if (post ~ /^[ \t\n]*\}/) sub(/,[ \t\n]*$/, "", pre)   # it was the last key: drop the comma before it
      s = pre post
    }
    entry = "  \"statusLine\": {\n    \"type\": \"command\",\n    \"command\": \"" cmd "\",\n    \"refreshInterval\": 1\n  }"
    p = index(s, "{")
    rest = substr(s, p + 1)
    sep = (rest ~ /^[ \t\n]*\}/) ? "\n" : ",\n"
    printf "%s", substr(s, 1, p) "\n" entry sep rest
  }
' "$settings" > "$settings.tmp.$$" && mv "$settings.tmp.$$" "$settings"

echo "Installed. Send a message in Claude Code to see the status line."
echo "Commands: /statusline-help, /statusline-toggle"
