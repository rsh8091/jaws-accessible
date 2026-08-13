param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = @(
    '1', '2025', 'duke', '1', '2003', 'syracuse', '1', '1',
    '1', '1', '1', 'confirm', 'continue', 'continue', 'auto', 'auto',
    '5', '6', '7', '1', '5', '2', '8', '3'
)

Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible offense menu exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Offense choices',
    '1. Pass to another player.',
    '2. Attempt a two-point shot.',
    '3. Attempt a three-point shot.',
    '5. Hear the game status.',
    '6. Hear the lineup.',
    'Enter 1 to pass, 2 for a two-point shot, or 3 for a three-point shot.',
    'Pass targets',
    'passes toward',
    'attempts a two-point shot.',
    'Gameplay test ended by user.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible offense-menu transcript did not contain: $expected`n$transcript"
    }
}

Write-Output 'Accessible offense-menu transcript test passed.'
