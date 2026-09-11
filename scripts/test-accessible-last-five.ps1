param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$setup = @('1','2025','duke','1','2003','syracuse','1','1','2','1','1','confirm','continue','continue','auto','1','1')
Push-Location (Split-Path -Parent $executablePath)
try {
    foreach ($choice in 0..5) {
        $transcript = ($setup + @([string]$choice,'3')) | & $executablePath --accessible --accessible-test --accessible-last-five-test 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or -not $transcript.Contains("Accepted final-five choice: $choice")) { throw "Choice $choice failed.`n$transcript" }
        if (-not $transcript.Contains('Late-game offensive decision.')) { throw 'Missing accessible menu.' }
    }
    $transcript = ($setup + @('1','4','3','invalid','','5','3')) | & $executablePath --accessible --accessible-test --accessible-last-five-test --restricted-choices 2>&1 | Out-String
    if (-not $transcript.Contains('Accepted final-five choice: 5')) { throw "Restricted choices failed.`n$transcript" }
    if (([regex]::Matches($transcript,'That choice is unavailable')).Count -ne 5) { throw "Invalid input was not rejected correctly.`n$transcript" }
    $transcript = ($setup + @('','5','3')) | & $executablePath --accessible --accessible-test --accessible-last-five-test --jaws-last-five-test 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or -not $transcript.Contains('Manual JAWS final-five-seconds test.') -or -not $transcript.Contains('Accepted final-five choice: 5')) { throw "JAWS scenario entry failed.`n$transcript" }
}
finally { Pop-Location }
Write-Output 'Final-five-second offensive choices passed: all six options, timeout ownership, disabled threes, unavailable timeout, and invalid input.'
