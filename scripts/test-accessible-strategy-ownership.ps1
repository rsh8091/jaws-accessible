param(
    [string]$Source = (Join-Path $PSScriptRoot '..\src\HELLO.BAS')
)

$ErrorActionPreference = 'Stop'

$text = Get-Content -LiteralPath $Source -Raw

$expectedText = @(
    'If accessiblePlayerOpt = 3 Then computerControlled = 1',
    'If accessiblePlayerOpt = 1 And team = 0 Then computerControlled = 1',
    'If accessiblePlayerOpt = 2 And team = 1 Then computerControlled = 1',
    'If computerControlled = 1 Then',
    'P9 = team',
    'Call CategorizeDefense(team)'
)

foreach ($expected in $expectedText) {
    if (-not $text.Contains($expected)) {
        throw "Accessible strategy ownership guard is missing: $expected"
    }
}

$badPattern = "If accessiblePreparedGame = 1 Then`r?`n\s+Call ComputerStrategy"
if ($text -match $badPattern) {
    throw 'Accessible setup still lets computer strategy overwrite every team.'
}

Write-Output 'Accessible strategy ownership regression test passed.'
