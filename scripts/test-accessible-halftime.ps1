param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = @(
    '1', '2025', 'duke', '1', '2003', 'syracuse', '1', '1',
    '2', '1', '1', 'confirm', 'continue', 'continue', 'auto', '1', '1',
    '4', '5', '5', '', '', '1', '3'
)

Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test --accessible-halftime-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible halftime transcript exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Automated halftime transition validation.',
    'Halftime.',
    '4. Make a halftime substitution.',
    'Current lineup for SYRACUSE.',
    'B.EDELIN replaces C.FORTH as center.',
    'Halftime substitution review complete.',
    'Choose 1 when you are ready to start the second half.',
    'Second-half possession reached after halftime substitution.',
    'Half 2, ',
    'Original simulator validation complete.',
    'Exiting Courtside College Basketball.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible halftime transcript did not contain: $expected`n$transcript"
    }
}

Write-Output 'Accessible halftime substitution and second-half transition test passed.'
