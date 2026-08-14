param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = @('1', '2025', 'duke', '1', '2003', 'syracuse', '1', '1', '4', '1', '1', 'confirm', 'continue', 'continue', '3')
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
    'Selected SYRACUSE as the home team.',
    'Visitor: DUKE (2025)',
    'Home: SYRACUSE (2003)',
    'Matchup confirmed: DUKE at SYRACUSE.',
    'Control: computer controls both teams.',
    'Location: home-court advantage.',
    'Shot clock: 30 seconds.',
    'Teams loaded successfully.',
    'Visiting team: DUKE',
    'Home team: SYRACUSE',
    'The computer selected this lineup.',
    'Home starting lineup for SYRACUSE.',
    'Confirmed starting lineups',
    '1. First guard:',
    '3. First forward:',
    '5. Center:',
    'Ready for tipoff.',
    'Original simulator validation.',
    'The original game engine will coach both teams for six possessions.',
    'Possession 1 of 6:',
    'Six original-simulator possessions completed.',
    'Original simulator validation complete.',
    'Exiting Courtside College Basketball.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible team-selection transcript did not contain: $expected`n$transcript"
    }
}

Write-Output 'Accessible team-selection transcript test passed.'
