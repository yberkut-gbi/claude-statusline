#!/usr/bin/env node
// Claude Code status line. Node.js only, no packages; works on macOS, Linux and Windows.
//   model (effort) | ctx: used/window (%) | session: ↑in ↓out ⛁ read/write mm:ss ($cost) | branch
// Usage:
//   node statusline.js            read Claude Code's JSON on stdin, print the line
//   node statusline.js --toggle   show/hide the line
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const OFF = path.join(os.homedir(), '.claude', 'statusline.off');

if (process.argv.includes('--toggle')) {
  if (fs.existsSync(OFF)) { fs.rmSync(OFF); console.log('Status line: shown'); }
  else { fs.writeFileSync(OFF, ''); console.log('Status line: hidden'); }
  process.exit(0);
}

const kfmt = (n) =>
  n >= 1e6 ? `${Math.floor(n / 1e4) / 100}M` :
  n >= 1e3 ? `${Math.floor(n / 100) / 10}k` :
  String(Math.floor(n));

// Session token totals, summed from the transcript (one entry per message id).
function sessionTokens(file) {
  const byId = new Map();
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    if (!line.includes('"usage"')) continue;
    try {
      const m = JSON.parse(line).message;
      if (m && m.id && m.usage) byId.set(m.id, m.usage);
    } catch { /* partial line while being written */ }
  }
  if (!byId.size) return null;
  const t = { in: 0, out: 0, read: 0, write: 0 };
  for (const u of byId.values()) {
    t.in += u.input_tokens || 0;
    t.out += u.output_tokens || 0;
    t.read += u.cache_read_input_tokens || 0;
    t.write += u.cache_creation_input_tokens || 0;
  }
  return t;
}

function gitBranch(cwd) {
  const git = (...args) => execFileSync('git', ['--no-optional-locks', '-C', cwd, ...args],
    { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 1000 }).trim();
  try { return git('symbolic-ref', '--short', '-q', 'HEAD'); } catch {}
  try { return git('rev-parse', '--short', 'HEAD'); } catch {}
  return '';
}

function render(d) {
  const parts = [];
  parts.push(d.model?.display_name || 'Claude');
  if (d.effort?.level) parts[0] += ` (${d.effort.level})`;

  // Context: use the auto-compact window (same as /context) when it is set and smaller than the model window.
  const cw = d.context_window || {};
  let win = cw.context_window_size;
  const acw = Number(process.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW);
  if (acw > 0 && (!win || acw < win)) win = acw;
  if (cw.total_input_tokens != null && win) {
    const tok = cw.total_input_tokens;
    parts.push(`ctx: ${kfmt(tok)}/${kfmt(win)} (${Math.round(tok * 100 / win)}%)`);
  } else if (cw.used_percentage != null) {
    parts.push(`ctx: ${Math.round(cw.used_percentage)}%`);
  }

  const sess = [];
  if (d.transcript_path && fs.existsSync(d.transcript_path)) {
    const t = sessionTokens(d.transcript_path);
    if (t) sess.push(`↑${kfmt(t.in)} ↓${kfmt(t.out)} ⛁ ${kfmt(t.read)}/${kfmt(t.write)}`);
  }
  // Time left before the prompt cache expires (mm:ss), or "cold" once it has.
  if (d.prompt_cache?.expires_at) {
    const left = Math.floor(d.prompt_cache.expires_at - Date.now() / 1000);
    sess.push(left > 0 ? `${Math.floor(left / 60)}:${String(left % 60).padStart(2, '0')}` : 'cold');
  }
  if (d.cost?.total_cost_usd != null) sess.push(`($${d.cost.total_cost_usd.toFixed(2)})`);
  if (sess.length) parts.push(`session: ${sess.join(' ')}`);

  const cwd = d.workspace?.current_dir || d.cwd;
  if (cwd && fs.existsSync(cwd)) {
    const branch = gitBranch(cwd);
    if (branch) parts.push(branch);
  }
  return parts.join(' | ');
}

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (c) => { raw += c; });
process.stdin.on('end', () => {
  if (fs.existsSync(OFF)) return;
  let d = {};
  try { d = JSON.parse(raw); } catch {}
  console.log(render(d));
});
