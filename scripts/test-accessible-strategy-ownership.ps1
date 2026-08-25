param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'),
    [string]$Source = (Join-Path $PSScriptRoot '..\src\HELLO.BAS')
)

$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$sourceText = Get-Content -LiteralPath $sourcePath -Raw

$requiredGuards = @(
    'If accessibleEngineMode = 1 And AccessibleComputerControlsTeam%(teamIdx) = 0 Then Exit Sub',
    'If accessibleEngineMode = 1 And AccessibleComputerControlsTeam%(P9) = 0 Then Exit Sub'
)
foreach ($guard in $requiredGuards) {
    if (-not $sourceText.Contains($guard)) {
        throw "Accessible strategy ownership guard is missing: $guard"
    }
}

$scriptedInput = [System.Collections.Generic.List[string]]::new()
@(
    '1', '2025', 'duke', '1', '2003', 'syracuse', '1', '1',
    '2', '1', '1', 'confirm', 'continue', 'continue', 'auto', '1', '1'
) | ForEach-Object { $scriptedInput.Add($_) }
$scriptedInput.Add('3')

Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test --accessible-strategy-ownership-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible strategy ownership test exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Control: human controls home; computer controls visitor.',
    'Automated accessible strategy ownership validation.',
    'Human strategy baseline: MOTION and SOLID MAN-TO-MAN.',
    'Human strategy ownership validation passed.',
    'Original simulator validation complete.'
)
foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible strategy ownership transcript did not contain: $expected`n$transcript"
    }
}

if ($transcript.Contains('Human strategy ownership validation failed.')) {
    throw "The computer changed a human-controlled strategy.`n$transcript"
}

Write-Output 'Accessible strategy ownership test passed.'
