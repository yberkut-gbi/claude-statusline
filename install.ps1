# Install the status line on Windows. Uses only built-in Windows PowerShell 5.1+.
#   powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1              install (or update)
#   powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Uninstall   remove it (same as uninstall.ps1)
# macOS / Linux: use install.sh.
param([switch]$Uninstall)
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $HOME '.claude'
$cmds = Join-Path $dest 'commands'
$settings = Join-Path $dest 'settings.json'
$utf8 = New-Object System.Text.UTF8Encoding $false

# Forward slashes: Claude Code may run the command through Git Bash, which eats backslashes.
$run = 'powershell -NoProfile -ExecutionPolicy Bypass -File "' + ($dest -replace '\\', '/') + '/statusline.ps1"'

# Rewrite "statusLine" in settings.json. Install: set ours. Uninstall: drop it only if it runs our script.
# A backup is kept next to the file.
function Set-StatusLine {
    $json = $null
    if (Test-Path $settings) {
        Copy-Item $settings "$settings.bak.$(Get-Date -Format yyyyMMddHHmmss)"
        $json = Get-Content -Raw -Encoding UTF8 $settings | ConvertFrom-Json
    } elseif ($Uninstall) { return }
    if (-not $json) { $json = New-Object PSObject }
    if ($Uninstall) {
        if ($json.statusLine -and "$($json.statusLine.command)" -match 'statusline\.(sh|ps1)') {
            $json.PSObject.Properties.Remove('statusLine')
        }
    } else {
        $statusLine = [ordered]@{ type = 'command'; command = $run; refreshInterval = 1 }
        $json | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine -Force
    }
    [IO.File]::WriteAllText($settings, ($json | ConvertTo-Json -Depth 100), $utf8)
}

if ($Uninstall) {
    Set-StatusLine
    foreach ($f in @('statusline.ps1', 'statusline.off', 'commands/statusline-help.md', 'commands/statusline-toggle.md')) {
        Remove-Item (Join-Path $dest $f) -Force -ErrorAction SilentlyContinue
    }
    'Uninstalled. The status line is gone after your next message.'
    exit 0
}

New-Item -ItemType Directory -Force -Path $cmds | Out-Null
Copy-Item (Join-Path $here 'src/statusline.ps1') $dest -Force
Copy-Item (Join-Path $here 'commands/statusline-help.md') $cmds -Force
$toggle = (Get-Content -Raw -Encoding UTF8 (Join-Path $here 'commands/statusline-toggle.md')).Replace('{{TOGGLE_COMMAND}}', "$run -Toggle")
[IO.File]::WriteAllText((Join-Path $cmds 'statusline-toggle.md'), $toggle, $utf8)
Set-StatusLine

'Installed. Send a message in Claude Code to see the status line.'
'Commands: /statusline-help, /statusline-toggle'
