# claude-statusline

A compact status line for [Claude Code](https://claude.com/claude-code). One script for macOS, Linux and Windows.

```
Opus 5.5 (medium) | ctx: 86.9k/500k (17%) | session: ↑74 ↓14.8k ⛁ 2.26M/194.2k 54:10 ($2.10) | main
```

## What it shows

| Part | Meaning |
|---|---|
| `Opus 5.5 (medium)` | Model and effort level |
| `ctx: 86.9k/500k (17%)` | Context used now / window size (percent). Matches `/context`. |
| `↑74 ↓14.8k` | Session totals: fresh input tokens, output tokens |
| `⛁ 2.26M/194.2k` | Session totals: cache read / cache write tokens |
| `54:10` | Time left before the prompt cache expires (`cold` once it has) |
| `($2.10)` | Estimated session cost in USD |
| `main` | Current git branch |

Inside Claude Code, run `/statusline-help` for the full explanation (for example, why cache read can be bigger than the context window).

## Requirements

- [Node.js](https://nodejs.org) 18 or newer, on your `PATH`. No npm packages.
- `git` (optional). Without it, the branch is not shown.

## Install

```sh
npx github:yberkut-gbi/claude-statusline install
```

No clone needed. Then send a message in Claude Code to see the line.

The installer:
- copies `statusline.js` to `~/.claude/`
- adds `/statusline-help` and `/statusline-toggle` to `~/.claude/commands/`
- sets `statusLine` in `~/.claude/settings.json` (a backup is saved first)

To update, run the same command again.

## Commands

| Command | What it does |
|---|---|
| `/statusline-help` | Explains each part of the line |
| `/statusline-toggle` | Hides or shows the line |

Plan and spend limits are not in the line. Use Claude Code's built-in `/usage` for those.

## Settings

- **Refresh rate:** the line refreshes every second so the cache timer counts down. To refresh less often, change `refreshInterval` in `~/.claude/settings.json`.
- **Context window:** if `CLAUDE_CODE_AUTO_COMPACT_WINDOW` is set, the line uses it as the window size, the same as `/context`.

## Troubleshooting

- **No line shows:** run `node --version` in a new terminal. If it fails, install Node.js or add it to your `PATH`.
- **Line shows only `Claude`:** Claude Code sent no data yet. Send a message.
- **Line is hidden:** run `/statusline-toggle`.

## Uninstall

```sh
npx github:yberkut-gbi/claude-statusline uninstall
```

It removes the script, the two commands, and the `statusLine` setting (only if it still points to this script). A backup of `settings.json` is saved first.

## Repository layout

```
bin/cli.js          the installer: install | uninstall
src/statusline.js   the status line (--toggle to show/hide)
commands/           Claude Code commands; the installer fills in {{TOGGLE_COMMAND}}
package.json        makes it runnable with npx
```
