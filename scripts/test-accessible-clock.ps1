param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$setup = @('1','2025','duke','1','2003','syracuse','1','1','2','1','1','confirm','continue','continue','auto','1','1')
# Numbered clock, alias, full status, repeated review requests, invalid entries,
# then an explicit pass. Two computer pauses exercise continue and end.
$commands = @('7','clock','invalid','','clock','','5','clock','','1','clock','clock','invalid','','clock','end','3')
Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = ($setup + $commands) | & $executablePath --accessible --accessible-test --accessible-clock-test 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Clock test exited with code $LASTEXITCODE.`n$transcript" }
} finally { Pop-Location }
foreach ($expected in @(
    'First half, 42 seconds remaining.', 'First half, 1 second remaining.',
    'First half, 0 seconds remaining.', 'Second half, 1 minute remaining.',
    'Second half, 1 minute 1 second remaining.', 'Second half, 2 minutes remaining.',
    'Overtime 1, 5 minutes remaining.', 'Overtime 2, 1 second remaining.',
    '7. Hear game clock.', 'Score:', 'Possession:', 'Shot clock: 19.',
    'Press Enter to return, or type clock.', 'Press Enter to continue, or type clock or end.',
    'CLOCK_TEST_PHASE 1 complete', 'CLOCK_TEST_PHASE 2 complete', 'CLOCK_TEST_PHASE 3 complete', 'CLOCK_TEST_COMPLETE'
)) {
    if (-not $transcript.Contains($expected)) { throw "Missing: $expected`n$transcript" }
}
if ($transcript.Contains('CLOCK_TEST_FAIL')) { throw "Game state changed during clock requests.`n$transcript" }
if (([regex]::Matches($transcript, 'Second half, 2 minutes 15 seconds remaining\.')).Count -ne 9) {
    throw "Repeated clock/status requests were not all handled at the same time.`n$transcript"
}
if (([regex]::Matches($transcript, 'Clock test computer possession pause\.')).Count -ne 2) {
    throw "Clock requests repeated or skipped narration.`n$transcript"
}
Write-Output 'Clock tests passed: formatting, numbered/typed requests, review, computer pauses, invalid input, unchanged state, continue and end.'
