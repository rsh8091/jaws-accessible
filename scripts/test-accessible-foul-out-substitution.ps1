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
$scriptedInput.Add('3')

Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test --accessible-foul-out-subs-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible foul-out substitution test exited with code $LASTEXITCODE.`n$transcript"
}

if (-not $transcript.Contains('Automated computer foul-out substitution validation.')) {
    throw "Accessible foul-out substitution test did not reach its deterministic scenario.`n$transcript"
}

if (-not $transcript.Contains('Computer foul-out substitution validation passed.')) {
    throw "Computer lineup selection retained a disqualified or duplicate player.`n$transcript"
}

Write-Output 'Accessible foul-out substitution test passed.'
