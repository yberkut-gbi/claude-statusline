#!/bin/bash
# Claude Code status line:
#   model (effort) | ctx: used/window (%) | session: ↑in ↓out ⛁ read/write mm:ss ($cost) | branch
# Hide it with:  touch ~/.claude/statusline.off   (show again: rm ~/.claude/statusline.off)
input=$(cat)
[ -f "$HOME/.claude/statusline.off" ] && exit 0
command -v jq >/dev/null 2>&1 || { echo "jq missing"; exit 0; }

j() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null | tr -d '\r'; }
kfmt() { awk -v s="$1" 'BEGIN{ if (s>=1000000) printf "%gM", int(s/10000)/100; else if (s>=1000) printf "%gk", int(s/100)/10; else printf "%d", s }'; }

model=$(j '.model.display_name')
effort=$(j '.effort.level')
used=$(j '.context_window.used_percentage')
size=$(j '.context_window.context_window_size')
tok=$(j '.context_window.total_input_tokens')
cost=$(j '.cost.total_cost_usd')
exp=$(j '.prompt_cache.expires_at')
tp=$(j '.transcript_path')
cwd=$(j '.workspace.current_dir // .cwd')

out="${model:-Claude}"
[ -n "$effort" ] && out="$out ($effort)"

# Use the auto-compact window (same as /context) when it is set and smaller than the model window.
win="$size"
acw="${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-}"
if [ -n "$acw" ] && { [ -z "$win" ] || [ "$acw" -lt "$win" ]; }; then win="$acw"; fi
if [ -n "$tok" ] && [ -n "$win" ]; then
  out="$out | ctx: $(kfmt "$tok")/$(kfmt "$win") ($(awk -v t="$tok" -v w="$win" 'BEGIN{ printf "%.0f", t*100/w }')%)"
elif [ -n "$used" ]; then
  out="$out | ctx: $(printf '%.0f' "$used")%"
fi

# Session token totals, summed from the transcript (one entry per message id).
if [ -n "$tp" ] && [ -f "$tp" ]; then
  read -r t_in t_out t_cr t_cw < <(jq -rn '
    [inputs | select(.message.usage and .message.id) | {key: .message.id, value: .message.usage}]
    | from_entries | [.[]]
    | [ (map(.input_tokens // 0) | add // 0),
        (map(.output_tokens // 0) | add // 0),
        (map(.cache_read_input_tokens // 0) | add // 0),
        (map(.cache_creation_input_tokens // 0) | add // 0) ] | @tsv' "$tp" 2>/dev/null | tr -d '\r')
fi
sess=""
[ -n "$t_in" ] && sess="↑$(kfmt "$t_in") ↓$(kfmt "$t_out") ⛁ $(kfmt "$t_cr")/$(kfmt "$t_cw")"
# Time left before the prompt cache expires (mm:ss), or "cold" once it has.
if [ -n "$exp" ]; then
  left=$(( ${exp%.*} - $(date +%s) ))
  if [ "$left" -gt 0 ]; then
    sess="${sess:+$sess }$(printf '%d:%02d' $((left / 60)) $((left % 60)))"
  else
    sess="${sess:+$sess }cold"
  fi
fi
[ -n "$cost" ] && sess="${sess:+$sess }(\$$(printf '%.2f' "$cost"))"
[ -n "$sess" ] && out="$out | session: $sess"

if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(git --no-optional-locks -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null \
    || git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && out="$out | $branch"
fi

printf '%s\n' "$out"
