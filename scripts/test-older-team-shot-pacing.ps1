param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$sourcePath = Join-Path $PSScriptRoot '..\src\HELLO.BAS'
$source = Get-Content -LiteralPath $sourcePath -Raw

$expectedSource = @(
    'Shared matchPace',
    'If teamGames <= 0 Or teamFGA <= 0 Then',
    'paceDataAvailable = 0',
    'If paceDataAvailable = 1 Then'
)

foreach ($expected in $expectedSource) {
    if (-not $source.Contains($expected)) {
        throw "The older-team pace fallback guard is missing: $expected"
    }
}

$scriptedInput = @(
    '1', '1988', 'syracuse', '1', '1988', 'pitt', '1', '1',
    '4', '1', '1', 'confirm', 'continue', 'continue', '3'
)

Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test --accessible-turnover-diagnostic 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Older-team shot-pacing regression exited with code $LASTEXITCODE.`n$transcript"
}

if (-not $transcript.Contains('TURNOVER_DIAGNOSTIC')) {
    throw "The 1988 diagnostic game did not complete.`n$transcript"
}

$paceMatch = [regex]::Match($transcript, 'PACE_DIAGNOSTIC match_pace=(-?\d+)')
if (-not $paceMatch.Success -or [int]$paceMatch.Groups[1].Value -le 0) {
    throw "The 1988 game did not pass a positive match pace to the older-team fallback.`n$transcript"
}

Write-Output 'Older-team shot-pacing regression test passed.'
