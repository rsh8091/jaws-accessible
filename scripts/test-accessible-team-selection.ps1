param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = @('1', '2025', 'duke', '1', '2025', 'akron', '1', '1', '2', '1', '1', 'confirm', '3')
Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible team selection exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Choose the visiting team.',
    'Selected DUKE as the visiting team.',
    'Choose the home team.',
    'Selected AKRON as the home team.',
    'Visitor: DUKE (2025)',
    'Home: AKRON (2025)',
    'Matchup confirmed: DUKE at AKRON.',
    'Control: human controls home; computer controls visitor.',
    'Location: home-court advantage.',
    'Shot clock: 30 seconds.',
    'Teams loaded successfully.',
    'Visiting team: DUKE',
    'Home team: AKRON',
    'Ready for tipoff.',
    'Exiting Courtside College Basketball.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible team-selection transcript did not contain: $expected`n$transcript"
    }
}

Write-Output 'Accessible team-selection transcript test passed.'
