#!/bin/sh
# Claude Code status line for macOS / Linux. Uses only POSIX sh, grep, sed, awk, date (git optional).
#   model (effort) | ctx: used/window (%) | session: ↑in ↓out ⛁ read/write mm:ss ($cost) | branch
# Keep in sync with statusline.ps1 (Windows).
#   statusline.sh            read Claude Code's JSON on stdin, print the line
#   statusline.sh --toggle   show/hide the line

off="$HOME/.claude/statusline.off"
if [ "$1" = "--toggle" ]; then
  if [ -f "$off" ]; then rm "$off" && echo "Status line: shown"; else : > "$off" && echo "Status line: hidden"; fi
  exit 0
fi

input=$(cat)
[ -f "$off" ] && exit 0

# jv KEY [SCOPE]: first scalar value of "KEY" in the input (after "SCOPE": when given).
jv() {
  s=$input
  [ -n "$2" ] && s=${s#*\"$2\":}
  printf '%s' "$s" | tr '\n' ' ' \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*(\"([^\"\\\\]|\\\\.)*\"|[-0-9.eE+]+)" | head -n 1 \
    | sed -E 's/^[^:]*:[[:space:]]*//; s/^"//; s/"$//; s/\\\\/\\/g; s/\\"/"/g'
}
kfmt() { awk -v s="$1" 'BEGIN{ if (s>=1000000) printf "%gM", int(s/10000)/100; else if (s>=1000) printf "%gk", int(s/100)/10; else printf "%d", s }'; }

model=$(jv display_name model)
effort=$(jv level effort)
tok=$(jv total_input_tokens context_window)
size=$(jv context_window_size context_window)
used=$(jv used_percentage context_window)
cost=$(jv total_cost_usd cost)
exp=$(jv expires_at prompt_cache)
tp=$(jv transcript_path)
cwd=$(jv current_dir workspace)
[ -n "$cwd" ] || cwd=$(jv cwd)

out=${model:-Claude}
[ -n "$effort" ] && out="$out ($effort)"

# Context: use the auto-compact window (same as /context) when it is set and smaller than the model window.
win=$size
acw=${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-}
if [ -n "$acw" ] && { [ -z "$win" ] || [ "$acw" -lt "$win" ]; }; then win=$acw; fi
if [ -n "$tok" ] && [ -n "$win" ]; then
  out="$out | ctx: $(kfmt "$tok")/$(kfmt "$win") ($(awk -v t="$tok" -v w="$win" 'BEGIN{ printf "%.0f", t*100/w }')%)"
elif [ -n "$used" ]; then
  out="$out | ctx: $(printf '%.0f' "$used")%"
fi

# Session token totals, summed from the transcript (one entry per message id).
sess=""
if [ -n "$tp" ] && [ -f "$tp" ]; then
  totals=$(awk '
    function num(s, k,   r) {
      if (match(s, "\"" k "\":[0-9]+")) { r = substr(s, RSTART, RLENGTH); sub(/.*:/, "", r); return r + 0 }
      return 0
    }
    index($0, "\"usage\"") && match($0, /"id":"msg_[A-Za-z0-9_]+"/) {
      id = substr($0, RSTART + 6, RLENGTH - 7)
      u = substr($0, index($0, "\"usage\""))
      i[id] = num(u, "input_tokens"); o[id] = num(u, "output_tokens")
      r[id] = num(u, "cache_read_input_tokens"); w[id] = num(u, "cache_creation_input_tokens")
    }
    END { for (k in i) { n++; ti += i[k]; to += o[k]; tr += r[k]; tw += w[k] } if (n) printf "%d %d %d %d", ti, to, tr, tw }
  ' "$tp" 2>/dev/null)
  if [ -n "$totals" ]; then
    set -- $totals
    sess="↑$(kfmt "$1") ↓$(kfmt "$2") ⛁ $(kfmt "$3")/$(kfmt "$4")"
  fi
fi
# Time left before the prompt cache expires (mm:ss), or "cold" once it has.
if [ -n "$exp" ]; then
  left=$(( ${exp%.*} - $(date +%s) ))
  if [ "$left" -gt 0 ]; then timer=$(printf '%d:%02d' $((left / 60)) $((left % 60))); else timer=cold; fi
  sess="${sess:+$sess }$timer"
fi
[ -n "$cost" ] && sess="${sess:+$sess }(\$$(printf '%.2f' "$cost"))"
[ -n "$sess" ] && out="$out | session: $sess"

# Git branch (short commit hash if detached).
if [ -n "$cwd" ] && [ -d "$cwd" ] && command -v git >/dev/null 2>&1; then
  branch=$(git --no-optional-locks -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null \
    || git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && out="$out | $branch"
fi

printf '%s\n' "$out"
