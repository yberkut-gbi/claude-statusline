# Install the status line on Windows. Uses only built-in Windows PowerShell 5.1+.
# Run:  powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1
# macOS / Linux: use install.sh.
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $HOME '.claude'
$cmds = Join-Path $dest 'commands'
$settings = Join-Path $dest 'settings.json'
$utf8 = New-Object System.Text.UTF8Encoding $false

# Forward slashes: Claude Code may run the command through Git Bash, which eats backslashes.
$run = 'powershell -NoProfile -ExecutionPolicy Bypass -File "' + ($dest -replace '\\', '/') + '/statusline.ps1"'

New-Item -ItemType Directory -Force -Path $cmds | Out-Null
Copy-Item (Join-Path $here 'src/statusline.ps1') $dest -Force
Copy-Item (Join-Path $here 'commands/statusline-help.md') $cmds -Force
$toggle = (Get-Content -Raw -Encoding UTF8 (Join-Path $here 'commands/statusline-toggle.md')).Replace('{{TOGGLE_COMMAND}}', "$run -Toggle")
[IO.File]::WriteAllText((Join-Path $cmds 'statusline-toggle.md'), $toggle, $utf8)

if (Test-Path $settings) {
    Copy-Item $settings "$settings.bak.$(Get-Date -Format yyyyMMddHHmmss)"
    $json = Get-Content -Raw -Encoding UTF8 $settings | ConvertFrom-Json
}
if (-not $json) { $json = New-Object PSObject }
$statusLine = [ordered]@{ type = 'command'; command = $run; refreshInterval = 1 }
$json | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine -Force
[IO.File]::WriteAllText($settings, ($json | ConvertTo-Json -Depth 100), $utf8)

'Installed. Send a message in Claude Code to see the status line.'
'Commands: /statusline-help, /statusline-toggle'
