param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = [System.Collections.Generic.List[string]]::new()
@(
    '1', '2025', 'duke', '1', '2003', 'syracuse', '1', '1',
    '2', '1', '1', 'confirm', 'continue', 'continue', 'auto', '1', '1',
    '2', '5', '5', '', '1', '3'
) | ForEach-Object { $scriptedInput.Add($_) }

Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test --accessible-computer-subs-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible timeout transcript exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Timeout options for SYRACUSE.',
    'You may make substitutions before continuing play.',
    'Timeouts remaining:',
    '2. Make a substitution.',
    'B.EDELIN replaces C.FORTH as center.',
    'Computer first-half substitution validation passed.',
    'Original simulator validation complete.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible timeout transcript did not contain: $expected`n$transcript"
    }
}

if ($transcript.Contains('Press Enter to return to dead-ball options:')) {
    throw "Accessible timeout transcript still contains a redundant return prompt.`n$transcript"
}

Write-Output 'Accessible timeout substitution test passed.'
