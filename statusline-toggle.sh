#!/bin/bash
# Show or hide the status line by adding or removing a flag file.
f="$HOME/.claude/statusline.off"
if [ -f "$f" ]; then
  rm "$f" && echo "Status line: shown"
else
  touch "$f" && echo "Status line: hidden"
fi
