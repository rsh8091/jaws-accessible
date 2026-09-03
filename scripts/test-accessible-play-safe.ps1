param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = @(
    '1', '2025', 'duke', '1', '2003', 'syracuse', '1', '1',
    '2', '1', '1', 'confirm', 'continue', 'continue', 'auto', '1', '1',
    '1', '', '1', '', '3'
)

Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test --accessible-play-safe-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible play-safe test exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Accessible play-safe menu validation.',
    'Players in foul trouble who can be made to play safe',
    'Choose a player number to play safe, or press Enter to continue the game:',
    'will now play safe.',
    'Press Enter to return to the defensive safety choices:',
    'Accessible play-safe menu returned to the game.'
)

foreach ($text in $expectedText) {
    if (-not $transcript.Contains($text)) {
        throw "Accessible play-safe transcript is missing '$text'.`n$transcript"
    }
}

$menuHeading = 'Players in foul trouble who can be made to play safe'
$headingCount = ([regex]::Matches($transcript, [regex]::Escape($menuHeading))).Count
if ($headingCount -ne 2) {
    throw "Expected the play-safe heading once for each selectable player, with no empty final announcement; found $headingCount.`n$transcript"
}

Write-Output 'Accessible play-safe menu test passed.'
