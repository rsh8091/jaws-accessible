param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = [System.Collections.Generic.List[string]]::new()
@(
    '1', '2025', 'duke', '1', '2003', 'syracuse', '1', '1',
    '2', '1', '1', 'confirm', 'continue', 'continue', 'auto', '1', '1'
) | ForEach-Object { $scriptedInput.Add($_) }

# Two is a valid second-player pass target and a two-point-shot choice.
# Extra entries safely cover random original-engine pass prompts.
1..40 | ForEach-Object { $scriptedInput.Add('2') }
$scriptedInput.Add('3')

Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible human-versus-computer transcript exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Control: human controls home; computer controls visitor.',
    'The original game engine will play one possession for each team.',
    'Computer play runs continuously. Your team pauses when a decision is required.',
    'Possession 1 of 2:',
    'Score:',
    'Offensive strategy:',
    'is running',
    'Defensive strategy:',
    'SHOT %',
    'Offensive choices',
    'Your team, SYRACUSE, is on offense.',
    'Shot clock:',
    'seconds remaining.',
    'shot chance:',
    'percent.',
    'Current situation:',
    '1. Pass.',
    '2. Attempt a two-point shot.',
    '3. Attempt a three-point shot.',
    '5. Hear score, clock, and possession.',
    '6. Hear lineup condition.',
    'Offensive style for SYRACUSE.',
    'Offensive style set to MOTION.',
    'Defensive style for SYRACUSE.',
    'Defensive style set to SOLID MAN-TO-MAN.',
    '2 original-simulator possessions completed.',
    'Original simulator validation complete.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible human-versus-computer transcript did not contain: $expected`n$transcript"
    }
}

Write-Output 'Accessible human-versus-computer transcript test passed.'
