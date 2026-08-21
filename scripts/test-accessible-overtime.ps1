param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = @(
    '1', '2025', 'duke', '1', '2003', 'syracuse', '1', '1',
    '2', '1', '1', 'confirm', 'continue', 'continue', 'auto', '1', '1',
    'continue', 'continue', '1', 'continue', '5', '3'
)

Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test --accessible-overtime-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible overtime transcript exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Automated accessible overtime validation.',
    'End of regulation.',
    'The score is tied: DUKE 70, SYRACUSE 70.',
    'Overtime 1 will be five minutes.',
    'Each team receives one additional timeout.',
    'Press Enter to begin overtime:',
    'Overtime possession reached through the original simulator.',
    'End of overtime 1.',
    'Final score: DUKE 70, SYRACUSE 72.',
    'The game is over.',
    'SYRACUSE defeated DUKE, 72 to 70.',
    'Overtime 1 scoring: DUKE 0, SYRACUSE 2.',
    'Exiting Courtside College Basketball.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible overtime transcript did not contain: $expected`n$transcript"
    }
}

Write-Output 'Accessible overtime transition test passed.'
