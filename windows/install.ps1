# Install the PowerShell status line, its commands, and the statusLine setting into ~/.claude.
# Run:  powershell -NoProfile -ExecutionPolicy Bypass -File windows\install.ps1
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$dest = Join-Path $HOME '.claude'
$cmds = Join-Path $dest 'commands'
$settings = Join-Path $dest 'settings.json'
$utf8 = New-Object System.Text.UTF8Encoding $false

New-Item -ItemType Directory -Force -Path $cmds | Out-Null
Copy-Item (Join-Path $here 'statusline.ps1') $dest -Force
Copy-Item (Join-Path $here 'statusline-toggle.ps1') $dest -Force
Copy-Item (Join-Path $root 'commands/statusline-help.md') $cmds -Force

# Forward slashes: Claude Code may run the command through Git Bash, which eats backslashes.
$slash = $dest -replace '\\', '/'
$run = 'powershell -NoProfile -ExecutionPolicy Bypass -File'

$toggle = @"
---
description: Show or hide the status line
---
!``$run "$slash/statusline-toggle.ps1"``

Reply with only the line above, word for word. Do nothing else.
"@
[IO.File]::WriteAllText((Join-Path $cmds 'statusline-toggle.md'), $toggle, $utf8)

if (Test-Path $settings) {
    Copy-Item $settings "$settings.bak.$(Get-Date -Format yyyyMMddHHmmss)"
    $json = Get-Content -Raw -Encoding UTF8 $settings | ConvertFrom-Json
} else {
    $json = New-Object PSObject
}
$statusLine = [ordered]@{
    type            = 'command'
    command         = "$run `"$slash/statusline.ps1`""
    refreshInterval = 1
}
$json | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine -Force
[IO.File]::WriteAllText($settings, ($json | ConvertTo-Json -Depth 100), $utf8)

Write-Output 'Installed. Send a message in Claude Code to see the status line.'
Write-Output 'Commands: /statusline-help, /statusline-toggle'
