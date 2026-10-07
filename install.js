#!/usr/bin/env node
// Install, update or remove the status line. Node.js only; works on macOS, Linux and Windows.
//   node install.js               install (or update)
//   node install.js --uninstall   remove it
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');

const uninstall = process.argv.includes('--uninstall');
const here = __dirname;
const dest = path.join(os.homedir(), '.claude');
const cmds = path.join(dest, 'commands');
const settingsFile = path.join(dest, 'settings.json');
// Forward slashes: on Windows, Claude Code may run commands through Git Bash, which eats backslashes.
const run = `node "${path.join(dest, 'statusline.js').replace(/\\/g, '/')}"`;
const ours = (sl) => /statusline\.(js|sh|ps1)/.test(sl?.command || '');

// Set our "statusLine" in settings.json, or remove it if it is ours. A backup is kept next to the file.
function updateSettings() {
  let settings = {};
  if (fs.existsSync(settingsFile)) {
    const stamp = new Date().toISOString().replace(/\D/g, '').slice(0, 14);
    fs.copyFileSync(settingsFile, `${settingsFile}.bak.${stamp}`);
    settings = JSON.parse(fs.readFileSync(settingsFile, 'utf8'));
  } else if (uninstall) {
    return;
  }
  if (uninstall) {
    if (ours(settings.statusLine)) delete settings.statusLine;
  } else {
    settings.statusLine = { type: 'command', command: run, refreshInterval: 1 };
  }
  fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2) + '\n');
}

if (uninstall) {
  updateSettings();
  for (const f of ['statusline.js', 'statusline.off', 'commands/statusline-help.md', 'commands/statusline-toggle.md']) {
    fs.rmSync(path.join(dest, f), { force: true });
  }
  console.log('Uninstalled. The status line is gone after your next message.');
} else {
  fs.mkdirSync(cmds, { recursive: true });
  fs.copyFileSync(path.join(here, 'src', 'statusline.js'), path.join(dest, 'statusline.js'));
  fs.copyFileSync(path.join(here, 'commands', 'statusline-help.md'), path.join(cmds, 'statusline-help.md'));
  const toggle = fs.readFileSync(path.join(here, 'commands', 'statusline-toggle.md'), 'utf8')
    .replace('{{TOGGLE_COMMAND}}', `${run} --toggle`);
  fs.writeFileSync(path.join(cmds, 'statusline-toggle.md'), toggle);
  updateSettings();
  console.log('Installed. Send a message in Claude Code to see the status line.');
  console.log('Commands: /statusline-help, /statusline-toggle');
}
