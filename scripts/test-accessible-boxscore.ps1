param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = & $executablePath --accessible --accessible-boxscore-test --accessible-boxscore-transition-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible box score transcript exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Accessible box score test mode.',
    'Automated accessible box score validation.',
    'SYRACUSE defeated DUKE, 78 to 72.',
    'DUKE team totals.',
    'Field goals:',
    'Combined player minutes:',
    'J. Blakes.',
    'D. Lively.',
    'Did not play.',
    'You have completed the visiting team player box score for DUKE.',
    'Moving to the home team player box score for SYRACUSE.',
    'B. EDELIN.',
    'You have completed the home team player box score for SYRACUSE.',
    'SYRACUSE team totals.',
    'SYRACUSE players.',
    'Exiting Courtside College Basketball.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible box score transcript did not contain: $expected`n$transcript"
    }
}

$menuInput = @('continue', '5', '3')
Push-Location (Split-Path -Parent $executablePath)
try {
    $menuTranscript = $menuInput | & $executablePath --accessible --accessible-boxscore-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if (-not $menuTranscript.Contains('Box score test complete. Returning to the accessible main menu.')) {
    throw "Interactive box score test did not return to the accessible main menu.`n$menuTranscript"
}

if (-not $menuTranscript.Contains('Main menu')) {
    throw "Accessible main menu was not shown after the box score test.`n$menuTranscript"
}

$htmlPath = Join-Path (Split-Path -Parent $executablePath) 'accessible-boxscore.html'
Push-Location (Split-Path -Parent $executablePath)
try {
    $htmlTranscript = & $executablePath --accessible --accessible-boxscore-test --accessible-boxscore-html-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $htmlPath)) {
    throw "Accessible HTML box score was not created.`n$htmlTranscript"
}

$html = Get-Content -LiteralPath $htmlPath -Raw
$expectedHtml = @(
    '<html lang="en">',
    '<h1>Courtside College Basketball box score</h1>',
    '<h2 id="summary-heading">Game summary</h2>',
    '<table aria-describedby="table-help">',
    '<caption>DUKE player and team statistics</caption>',
    '<caption>SYRACUSE player and team statistics</caption>',
    '<th scope="col">Player</th>',
    '<th scope="row">J. ROACH</th>',
    '<th scope="row">Team totals</th>',
    '<td>DNP</td>'
)

foreach ($expected in $expectedHtml) {
    if (-not $html.Contains($expected)) {
        throw "Accessible HTML box score did not contain: $expected"
    }
}

Write-Output 'Accessible spoken box score test passed.'
