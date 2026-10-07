# Show or hide the status line by adding or removing a flag file.
$f = Join-Path $HOME '.claude/statusline.off'
if (Test-Path $f) {
    Remove-Item $f
    Write-Output 'Status line: shown'
} else {
    New-Item -ItemType File -Path $f -Force | Out-Null
    Write-Output 'Status line: hidden'
}
