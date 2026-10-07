# Claude Code status line (PowerShell version, for Windows without Git Bash).
#   model (effort) | ctx: used/window (%) | session: in out cache read/write mm:ss ($cost) | branch
# Hide it with /statusline-toggle (creates ~/.claude/statusline.off).
# Works in Windows PowerShell 5.1 and PowerShell 7. Non-ASCII symbols are built from code points
# so the file can be saved without a BOM.

$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$raw = [Console]::In.ReadToEnd()

if (Test-Path (Join-Path $HOME '.claude/statusline.off')) { exit 0 }

$inv = [Globalization.CultureInfo]::InvariantCulture
$UP = [char]0x2191; $DOWN = [char]0x2193; $CACHE = [char]0x26C1

function KFmt([double]$s) {
    if ($s -ge 1000000) { return ([Math]::Floor($s / 10000) / 100).ToString('0.##', $inv) + 'M' }
    if ($s -ge 1000)    { return ([Math]::Floor($s / 100) / 10).ToString('0.#', $inv) + 'k' }
    return ([Math]::Floor($s)).ToString('0', $inv)
}

# First number a regex captures in $text, or 0.
function Num([regex]$re, [string]$text) {
    $m = $re.Match($text)
    if ($m.Success) { return [double]$m.Groups[1].Value }
    return 0
}

try { $d = $raw | ConvertFrom-Json } catch { $d = $null }
if (-not $d) { Write-Output 'Claude'; exit 0 }

$out = if ($d.model.display_name) { $d.model.display_name } else { 'Claude' }
if ($d.effort.level) { $out += " ($($d.effort.level))" }

# Context: use the auto-compact window (same as /context) when it is set and smaller than the model window.
$cw = $d.context_window
$win = if ($cw.context_window_size) { [double]$cw.context_window_size } else { $null }
$acw = $env:CLAUDE_CODE_AUTO_COMPACT_WINDOW
if ($acw -and ((-not $win) -or ([double]$acw -lt $win))) { $win = [double]$acw }
if ($cw.total_input_tokens -ne $null -and $win) {
    $tok = [double]$cw.total_input_tokens
    $pct = [Math]::Round($tok * 100 / $win)
    $out += " | ctx: $(KFmt $tok)/$(KFmt $win) ($pct%)"
} elseif ($cw.used_percentage -ne $null) {
    $out += " | ctx: $([Math]::Round([double]$cw.used_percentage))%"
}

# Session token totals, summed from the transcript (one entry per message id).
# Regex instead of ConvertFrom-Json per line: much faster on big transcripts.
$sess = ''
$tp = $d.transcript_path
if ($tp -and (Test-Path -LiteralPath $tp)) {
    $byId = @{}
    $reId = [regex]'"id":"(msg_[A-Za-z0-9_]+)"'
    $reIn = [regex]'"input_tokens":(\d+)'
    $reOut = [regex]'"output_tokens":(\d+)'
    $reCr = [regex]'"cache_read_input_tokens":(\d+)'
    $reCw = [regex]'"cache_creation_input_tokens":(\d+)'
    foreach ($line in [IO.File]::ReadLines($tp)) {
        if ($line.IndexOf('"usage"') -lt 0) { continue }
        $m = $reId.Match($line)
        if (-not $m.Success) { continue }
        $u = $line.Substring($line.IndexOf('"usage"'))
        $byId[$m.Groups[1].Value] = @(
            (Num $reIn $u), (Num $reOut $u), (Num $reCr $u), (Num $reCw $u)
        )
    }
    if ($byId.Count -gt 0) {
        $t = @(0, 0, 0, 0)
        foreach ($v in $byId.Values) { for ($i = 0; $i -lt 4; $i++) { $t[$i] += $v[$i] } }
        $sess = "$UP$(KFmt $t[0]) $DOWN$(KFmt $t[1]) $CACHE $(KFmt $t[2])/$(KFmt $t[3])"
    }
}

# Time left before the prompt cache expires (mm:ss), or "cold" once it has.
if ($d.prompt_cache.expires_at) {
    $left = [long][Math]::Floor([double]$d.prompt_cache.expires_at) - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $timer = if ($left -gt 0) { '{0}:{1:00}' -f [Math]::Floor($left / 60), ($left % 60) } else { 'cold' }
    $sess = ("$sess $timer").Trim()
}
if ($d.cost.total_cost_usd -ne $null) {
    $sess = ("$sess (`$" + ([double]$d.cost.total_cost_usd).ToString('0.00', $inv) + ')').Trim()
}
if ($sess) { $out += " | session: $sess" }

# Git branch (short commit hash if detached).
$cwd = if ($d.workspace.current_dir) { $d.workspace.current_dir } else { $d.cwd }
if ($cwd -and (Test-Path -LiteralPath $cwd) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    $branch = git --no-optional-locks -C "$cwd" symbolic-ref --short -q HEAD 2>$null
    if (-not $branch) { $branch = git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>$null }
    if ($branch) { $out += " | $branch" }
}

Write-Output $out
