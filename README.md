# claude-statusline

A compact status line for Claude Code.

```
Opus 5.5 (medium) | ctx: 86.9k/500k (17%) | session: ↑74 ↓14.8k ⛁ 2.26M/194.2k 54:10 ($2.10) | main
```

## Install

Needs `bash` and `jq`.

```sh
bash install.sh
```

It copies `statusline.sh` and the commands into `~/.claude`, and sets `statusLine` in `~/.claude/settings.json` (a backup is saved next to it).

## Use

- `/statusline-help` — explains each part of the line.
- `/statusline-toggle` — hides or shows the line.

## Uninstall

Remove the `statusLine` key from `~/.claude/settings.json`, then delete `~/.claude/statusline.sh`, `~/.claude/statusline-toggle.sh`, `~/.claude/commands/statusline-help.md` and `~/.claude/commands/statusline-toggle.md`.
