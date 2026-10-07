# claude-statusline

A compact status line for [Claude Code](https://claude.com/claude-code). One script for macOS, Linux and Windows. Needs only Node.js (no packages).

```
Opus 5.5 (medium) | ctx: 86.9k/500k (17%) | session: ↑74 ↓14.8k ⛁ 2.26M/194.2k 54:10 ($2.10) | main
```

Run `/statusline-help` inside Claude Code for what each part means.

## Install

```sh
git clone https://github.com/yberkut-gbi/claude-statusline.git
cd claude-statusline
node install.js
```

It copies `statusline.js` to `~/.claude/`, adds two commands to `~/.claude/commands/`, and sets `statusLine` in `~/.claude/settings.json`. It saves a backup of `settings.json` first. Run it again to update.

`git` is optional; without it the branch is not shown.

## Commands

- `/statusline-help` — explains each part of the line.
- `/statusline-toggle` — hides or shows the line.

## Uninstall

```sh
node install.js --uninstall
```

It removes the script, the two commands, and the `statusLine` setting (only if it still points to this script). It saves a backup of `settings.json` first.

## Layout

```
src/statusline.js   the status line (--toggle to show/hide)
commands/           Claude Code commands; {{TOGGLE_COMMAND}} is filled in by the installer
install.js          install / update (--uninstall to remove)
```

The line refreshes every second (`refreshInterval: 1`) so the cache timer counts down. Raise it in `settings.json` if that feels heavy.
