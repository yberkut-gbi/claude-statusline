#!/bin/sh
# Install the status line on macOS / Linux. Uses only POSIX sh, sed, awk.
#   install.sh               install (or update)
#   install.sh --uninstall   remove it (same as uninstall.sh)
# Windows: use install.ps1.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
dest="$HOME/.claude"
settings="$dest/settings.json"
run="sh ~/.claude/statusline.sh"
mode=install
[ "${1:-}" = "--uninstall" ] && mode=uninstall

# Rewrite "statusLine" in settings.json. install: drop any old one and insert ours after the first "{".
# uninstall: drop it only if it runs our script. A backup is kept next to the file.
set_status_line() {
  [ -f "$settings" ] || { [ "$mode" = uninstall ] && return 0; echo '{}' > "$settings"; }
  cp "$settings" "$settings.bak.$(date +%Y%m%d%H%M%S)"
  awk -v cmd="$run" -v mode="$mode" '
    { s = s $0 "\n" }
    END {
      if (match(s, /"statusLine"[ \t\n]*:[ \t\n]*\{[^}]*\}[ \t\n]*,?/) \
          && (mode == "install" || substr(s, RSTART, RLENGTH) ~ /statusline\.(sh|ps1)/)) {
        pre = substr(s, 1, RSTART - 1); post = substr(s, RSTART + RLENGTH)
        if (post ~ /^[ \t\n]*\}/) sub(/,[ \t\n]*$/, "", pre)   # it was the last key: drop the comma before it
        s = pre post
      }
      if (mode == "install") {
        entry = "  \"statusLine\": {\n    \"type\": \"command\",\n    \"command\": \"" cmd "\",\n    \"refreshInterval\": 1\n  }"
        p = index(s, "{")
        rest = substr(s, p + 1)
        sep = (rest ~ /^[ \t\n]*\}/) ? "\n" : ",\n"
        s = substr(s, 1, p) "\n" entry sep rest
      }
      printf "%s", s
    }
  ' "$settings" > "$settings.tmp.$$" && mv "$settings.tmp.$$" "$settings"
}

if [ "$mode" = uninstall ]; then
  set_status_line
  rm -f "$dest/statusline.sh" "$dest/statusline.off" \
    "$dest/commands/statusline-help.md" "$dest/commands/statusline-toggle.md"
  echo "Uninstalled. The status line is gone after your next message."
  exit 0
fi

mkdir -p "$dest/commands"
cp "$here/src/statusline.sh" "$dest/statusline.sh"
cp "$here/commands/statusline-help.md" "$dest/commands/"
sed "s|{{TOGGLE_COMMAND}}|$run --toggle|" "$here/commands/statusline-toggle.md" > "$dest/commands/statusline-toggle.md"
set_status_line

echo "Installed. Send a message in Claude Code to see the status line."
echo "Commands: /statusline-help, /statusline-toggle"
