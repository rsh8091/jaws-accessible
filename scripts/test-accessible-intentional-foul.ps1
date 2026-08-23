param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = @(
    '1', '2025', 'duke', '1', '2003', 'syracuse', '1', '1',
    '2', '1', '1', 'confirm', 'continue', 'continue', 'auto', '1', '1',
    '1', '2', '3'
)

Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test --accessible-intentional-foul-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Strategic-foul engine test exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Automated late-game strategic foul validation.',
    'Late-game defensive decision.',
    'Should SYRACUSE foul to stop the clock?',
    '1. Continue defending without fouling.',
    '2. Foul and choose the defender.',
    'Strategic foul prompt validation passed.',
    'Strategic foul recorded; exercising the seven-foul one-and-one path.',
    '1+1 FT:',
    'Strategic foul engine validation passed.',
    'Original simulator validation complete.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Strategic-foul engine transcript did not contain: $expected`n$transcript"
    }
}

if ($transcript.Contains('Current lineup for')) {
    throw "Strategic foul unexpectedly entered a roster menu before the free throws.`n$transcript"
}

Write-Output 'Strategic-foul engine test passed.'
