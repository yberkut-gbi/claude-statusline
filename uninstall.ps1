# Remove the status line on Windows. macOS / Linux: use uninstall.sh.
# Run:  powershell -NoProfile -ExecutionPolicy Bypass -File uninstall.ps1
& (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'install.ps1') -Uninstall
