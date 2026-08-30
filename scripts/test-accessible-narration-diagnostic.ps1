param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$executableDirectory = Split-Path -Parent $executablePath
$logPath = Join-Path $executableDirectory 'accessible-narration.log'
$scriptedInput = @('1', '2025', 'syracuse', '1', '2025', 'boston col', '1', '1', '4', '1', '1', 'confirm', 'continue', 'continue', '3')

Push-Location $executableDirectory
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test --accessible-narration-diagnostic 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible narration diagnostic exited with code $LASTEXITCODE.`n$transcript"
}

if (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) {
    throw "Accessible narration diagnostic did not create $logPath."
}

$log = Get-Content -Raw -LiteralPath $logPath
foreach ($expected in @('Accessible narration diagnostic', 'QUEUE|sequence=', 'FLUSH_BEGIN|', 'PRINT|sequence=', 'FLUSH_END', 'DIAGNOSTIC_END|')) {
    if (-not $log.Contains($expected)) {
        throw "Accessible narration diagnostic log did not contain: $expected`n$log"
    }
}

$queued = [regex]::Matches($log, '(?m)^QUEUE\|sequence=(\d+)') | ForEach-Object { $_.Groups[1].Value }
$printed = [regex]::Matches($log, '(?m)^PRINT\|sequence=(\d+)') | ForEach-Object { $_.Groups[1].Value }
if (@($queued).Count -ne @($printed).Count -or (Compare-Object $queued $printed)) {
    throw "Queued and printed narration sequence numbers differ.`n$log"
}

Write-Output 'Accessible narration diagnostic test passed.'
