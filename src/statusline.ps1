# Claude Code status line for Windows. Uses only built-in Windows PowerShell 5.1+ (git optional).
#   model (effort) | ctx: used/window (%) | session: in out cache read/write mm:ss ($cost) | branch
# Keep in sync with statusline.sh (macOS / Linux).
#   statusline.ps1           read Claude Code's JSON on stdin, print the line
#   statusline.ps1 -Toggle   show/hide the line
# Non-ASCII symbols are built from code points so the file needs no BOM.
param([switch]$Toggle)

$ErrorActionPreference = 'SilentlyContinue'
$off = Join-Path $HOME '.claude/statusline.off'
if ($Toggle) {
    if (Test-Path $off) { Remove-Item $off; 'Status line: shown' }
    else { New-Item -ItemType File -Path $off -Force | Out-Null; 'Status line: hidden' }
    exit 0
}

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$raw = [Console]::In.ReadToEnd()
if (Test-Path $off) { exit 0 }

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
if (-not $d) { 'Claude'; exit 0 }

$out = if ($d.model.display_name) { $d.model.display_name } else { 'Claude' }
if ($d.effort.level) { $out += " ($($d.effort.level))" }

# Context: use the auto-compact window (same as /context) when it is set and smaller than the model window.
$cw = $d.context_window
$win = if ($cw.context_window_size) { [double]$cw.context_window_size } else { $null }
$acw = $env:CLAUDE_CODE_AUTO_COMPACT_WINDOW
if ($acw -and ((-not $win) -or ([double]$acw -lt $win))) { $win = [double]$acw }
if ($null -ne $cw.total_input_tokens -and $win) {
    $tok = [double]$cw.total_input_tokens
    $out += " | ctx: $(KFmt $tok)/$(KFmt $win) ($([Math]::Round($tok * 100 / $win))%)"
} elseif ($null -ne $cw.used_percentage) {
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
        $at = $line.IndexOf('"usage"')
        if ($at -lt 0) { continue }
        $m = $reId.Match($line)
        if (-not $m.Success) { continue }
        $u = $line.Substring($at)
        $byId[$m.Groups[1].Value] = @((Num $reIn $u), (Num $reOut $u), (Num $reCr $u), (Num $reCw $u))
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
    $sess = "$sess $timer".Trim()
}
if ($null -ne $d.cost.total_cost_usd) {
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

$out
