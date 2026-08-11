param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = @('2', '1', 'not-a-command', '3')
$transcript = $scriptedInput | & $executablePath --accessible 2>&1 | Out-String

if ($LASTEXITCODE -ne 0) {
    throw "Accessible menu exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Accessible command-line mode.',
    'Accessibility help',
    'Single-game setup will be connected in the next development phase.',
    'Choice not recognized.',
    'Exiting Courtside College Basketball.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible menu transcript did not contain: $expected`n$transcript"
    }
}

Write-Output 'Accessible menu transcript test passed.'
