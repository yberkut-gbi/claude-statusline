#!/usr/bin/env node
// claude-statusline CLI. Node.js only; works on macOS, Linux and Windows.
//   claude-statusline install     install or update
//   claude-statusline uninstall   remove it
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');

const USAGE = `Usage: claude-statusline <command>

Commands:
  install     Install or update the status line in ~/.claude
  uninstall   Remove it

Run with npx, no clone needed:
  npx github:yberkut-gbi/claude-statusline install`;

const pkg = path.join(__dirname, '..');
const dest = path.join(os.homedir(), '.claude');
const cmds = path.join(dest, 'commands');
const settingsFile = path.join(dest, 'settings.json');
// Forward slashes: on Windows, Claude Code may run commands through Git Bash, which eats backslashes.
const run = `node "${path.join(dest, 'statusline.js').replace(/\\/g, '/')}"`;
const offFile = path.join(dest, 'statusline.off').replace(/\\/g, '/');
const ours = (sl) => /statusline\.(js|sh|ps1)/.test(sl?.command || '');

// Apply change(settings) to settings.json. A backup is kept next to the file.
function editSettings(change) {
  let settings = {};
  if (fs.existsSync(settingsFile)) {
    const stamp = new Date().toISOString().replace(/\D/g, '').slice(0, 14);
    fs.copyFileSync(settingsFile, `${settingsFile}.bak.${stamp}`);
    settings = JSON.parse(fs.readFileSync(settingsFile, 'utf8'));
  }
  change(settings);
  fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2) + '\n');
}

function install() {
  fs.mkdirSync(cmds, { recursive: true });
  fs.copyFileSync(path.join(pkg, 'src', 'statusline.js'), path.join(dest, 'statusline.js'));
  fs.copyFileSync(path.join(pkg, 'commands', 'statusline-help.md'), path.join(cmds, 'statusline-help.md'));
  const toggle = fs.readFileSync(path.join(pkg, 'commands', 'statusline-toggle.md'), 'utf8')
    .replace('{{TOGGLE_COMMAND}}', `${run} --toggle`);
  fs.writeFileSync(path.join(cmds, 'statusline-toggle.md'), toggle);
  editSettings((s) => {
    s.statusLine = { type: 'command', command: run, refreshInterval: 1 };
    // /statusline-toggle runs in the Bash sandbox, which blocks writes to ~/.claude by default.
    const fsSettings = ((s.sandbox ??= {}).filesystem ??= {});
    const allow = (fsSettings.allowWrite ??= []);
    if (!allow.includes(offFile)) allow.push(offFile);
  });
  console.log('Installed. Send a message in Claude Code to see the status line.');
  console.log('Commands: /statusline-help, /statusline-toggle');
}

function uninstall() {
  // Remove "statusLine" only if it still runs this script.
  if (fs.existsSync(settingsFile)) {
    editSettings((s) => {
      if (ours(s.statusLine)) delete s.statusLine;
      const fsSettings = s.sandbox?.filesystem;
      if (fsSettings?.allowWrite) {
        fsSettings.allowWrite = fsSettings.allowWrite.filter((p) => p !== offFile);
        if (!fsSettings.allowWrite.length) delete fsSettings.allowWrite;
        if (!Object.keys(fsSettings).length) delete s.sandbox.filesystem;
        if (!Object.keys(s.sandbox).length) delete s.sandbox;
      }
    });
  }
  for (const f of ['statusline.js', 'statusline.off', 'commands/statusline-help.md', 'commands/statusline-toggle.md']) {
    fs.rmSync(path.join(dest, f), { force: true });
  }
  console.log('Uninstalled. The status line is gone after your next message.');
}

const commands = { install, uninstall };
const cmd = commands[process.argv[2]];
if (!cmd) {
  console.log(USAGE);
  process.exit(process.argv[2] && !['help', '-h', '--help'].includes(process.argv[2]) ? 1 : 0);
}
cmd();
