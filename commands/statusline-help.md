---
description: Explain each part of the status line
---
Explain the status line to the user in plain, short words. Use this reference. Do not run any tools.

Example line:
`Opus 5.5 (medium) | ctx: 86.9k/500k (17%) | session: ↑74 ↓14.8k ⛁ 2.26M/194.2k 54:10 ($2.10) | main`

1. **`Opus 5.5 (medium)`** — the current model, and the effort level in brackets (shown only if the model supports effort).
2. **`ctx: 86.9k/500k (17%)`** — how full the conversation is right now: tokens in context / window size (percent). The window is `CLAUDE_CODE_AUTO_COMPACT_WINDOW` when set and smaller than the model's window, so it matches `/context`. This is a snapshot and goes up as the chat grows.
3. **`session:`** — running totals for this session (main conversation only; subagents keep their own logs):
   - **`↑74`** — fresh input tokens, not served from cache. Usually tiny, because almost everything is cached.
   - **`↓14.8k`** — output tokens Claude wrote.
   - **`⛁ 2.26M/194.2k`** — cache read / cache write. Every request re-sends the whole conversation; the already-cached part counts as a cache read. So cache read sums the context over all requests and can be far larger than the window. Cache reads cost about a tenth of fresh input. Cache write is the new part saved each time; it grows extra when the cache is rebuilt (for example after a model change or after the cache expires).
   - **`54:10`** — minutes:seconds until the prompt cache expires. `cold` means it has expired, and the next request rebuilds it (costs more).
   - **`($2.10)`** — estimated cost of this session in USD.
   - One request: fresh input + cache read + cache write ≈ `ctx`.
4. **`main`** — the current git branch (short commit hash if detached; hidden outside a git repo).

Extra tips:
- `/statusline-toggle` hides or shows the line.
- `/usage` shows plan and spend limits; `/context` shows the context breakdown.
