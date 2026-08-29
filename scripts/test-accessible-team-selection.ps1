param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = @('1', '2025', 'michigan state', '1', '2025', "saint mary's", '1', '1', '4', '1', '1', 'confirm', 'continue', 'continue', '3')
Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible team selection exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Choose the visiting team.',
    'Selected MICHIGAN ST as the visiting team.',
    'Choose the home team.',
    "Selected MT ST MARY'S as the home team.",
    'Visitor: MICHIGAN ST (2025)',
    "Home: MT ST MARY'S (2025)",
    "Matchup confirmed: MICHIGAN ST at MT ST MARY'S.",
    'Control: computer controls both teams.',
    'Location: home-court advantage.',
    'Shot clock: 30 seconds.',
    'Teams loaded successfully.',
    'Visiting team: MICHIGAN ST',
    "Home team: MT ST MARY'S",
    'The computer selected this lineup.',
    "Home starting lineup for MT ST MARY'S.",
    'Starting lineups confirmed. Next, choose your offensive and defensive styles.',
    '1. First guard:',
    '3. First forward:',
    '5. Center:',
    'Ready for tipoff.',
    'Original simulator validation.',
    'The original game engine will coach both teams for six possessions.',
    'Possession 1 of 6:',
    '6 original-simulator possessions completed.',
    'Original simulator validation complete.',
    'Exiting Courtside College Basketball.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible team-selection transcript did not contain: $expected`n$transcript"
    }
}

if ([regex]::Matches($transcript, 'Visiting lineup:').Count -ne 1 -or [regex]::Matches($transcript, 'Home lineup:').Count -ne 1) {
    throw "Starting lineups were read more than once.`n$transcript"
}

Write-Output 'Accessible team-selection transcript test passed.'
