param(
    [string]$Source = (Join-Path $PSScriptRoot '..\src\HELLO.BAS'),
    [string]$AccessibleSource = (Join-Path $PSScriptRoot '..\src\AccessibleMode.bm')
)

$ErrorActionPreference = 'Stop'
$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$text = Get-Content -LiteralPath $sourcePath -Raw
$accessibleSourcePath = (Resolve-Path -LiteralPath $AccessibleSource).Path
$accessibleText = Get-Content -LiteralPath $accessibleSourcePath -Raw
$combinedText = $text + $accessibleText

$freeThrowsStart = $text.IndexOf('Sub FreeThrows (ftCount, missedLastFT)')
$freeThrowsEnd = $text.IndexOf('End Sub', $freeThrowsStart)
if ($freeThrowsStart -lt 0 -or $freeThrowsEnd -lt 0) {
    throw 'Could not locate the FreeThrows routine.'
}
$freeThrowsText = $text.Substring($freeThrowsStart, $freeThrowsEnd - $freeThrowsStart)

$required = @(
    'If strategicFoul = 0 Then Call STOPPAGE(takeTO)',
    'If intentional = 0 And strategicFoul = 0 Then Call STOPPAGE(takeTO)',
    'DESIGNATED FOULER (1-5)',
    'desigFouler = Val(I$) - 1',
    'If accessibleEngineMode = 1 And (playerMode = 0 Or playerMode = 1 And D <> compTeam) Then',
    '--jaws-intentional-foul-test',
    'Selected "; players$(teamIdx, lineupIdx(teamIdx, selectedNumber - 1)); " to commit the foul.',
    'Loop Until Len(I$) = 1 And I$ >= "1" And I$ <= "5"',
    'currHalf >= 2 And gameClock! < 240',
    'playerStamina%(D, lineupIdx(D, foulPlayer))'
)

foreach ($expected in $required) {
    if (-not $combinedText.Contains($expected)) {
        throw "Intentional-foul regression guard is missing: $expected"
    }
}

if (-not $freeThrowsText.Contains('If intentional = 0 And strategicFoul = 0 Then Call STOPPAGE(takeTO)')) {
    throw 'The intentional-foul stoppage guard is not in the FreeThrows routine.'
}

if ($text.Contains('currHalf >= 4 And gameClock! < 240')) {
    throw 'The regulation intentional-foul condition has regressed to overtime-only.'
}

if ($text.Contains('DESIGNATED FOULER (0-4)')) {
    throw 'A designated-fouler prompt still exposes zero-based engine slots.'
}

Write-Output 'Intentional-foul transition regression test passed.'
