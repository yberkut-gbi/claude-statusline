# claude-statusline

A compact status line for [Claude Code](https://claude.com/claude-code). Works on macOS, Linux and Windows with no extra installs.

```
Opus 5.5 (medium) | ctx: 86.9k/500k (17%) | session: ↑74 ↓14.8k ⛁ 2.26M/194.2k 54:10 ($2.10) | main
```

Run `/statusline-help` inside Claude Code for what each part means.

## Install

```sh
git clone https://github.com/yberkut-gbi/claude-statusline.git
cd claude-statusline
```

| System | Command | Uses |
|---|---|---|
| macOS / Linux | `sh install.sh` | `sh`, `grep`, `sed`, `awk` |
| Windows | `powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1` | Windows PowerShell 5.1+ |

`git` is optional; without it the branch is not shown.

The installer copies the script to `~/.claude/`, adds the two commands to `~/.claude/commands/`, and sets `statusLine` in `~/.claude/settings.json`. It saves a backup of `settings.json` first.

## Commands

- `/statusline-help` — explains each part of the line.
- `/statusline-toggle` — hides or shows the line.

## Layout

```
src/statusline.sh      the status line, macOS / Linux
src/statusline.ps1     the status line, Windows (same output)
commands/              Claude Code commands, shared by both systems
install.sh, install.ps1
```

The line refreshes every second (`refreshInterval: 1`) so the cache timer counts down. Raise it in `settings.json` if that feels heavy.

## Uninstall

Remove the `statusLine` key from `~/.claude/settings.json`, then delete `~/.claude/statusline.sh` (or `statusline.ps1`), `~/.claude/statusline.off` if present, and `~/.claude/commands/statusline-help.md` and `statusline-toggle.md`.
