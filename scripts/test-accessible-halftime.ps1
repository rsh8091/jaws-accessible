param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path $Executable).Path
$results = Join-Path $PSScriptRoot '..\dist\halftime-tests'
New-Item -ItemType Directory -Force -Path $results | Out-Null
$results = (Resolve-Path $results).Path
$setup = @('1','2025','duke','1','2003','syracuse','1','1','2','1','1','confirm','continue','continue','auto','1','1')
$cases = @(
    @{Name='home'; Control='home'; Commands=@('6','10','3','7','15','2','3','','4','5','5','3','','1','','3'); Expected=@('HALFTIME_STATE team=1 offense=2 defense=1 coverage=1','B.EDELIN replaces C.FORTH as center.','only available during the last three minutes'); Start=$true},
    @{Name='visitor'; Control='visitor'; Commands=@('6','3','7','2','1','','3'); Expected=@('HALFTIME_STATE team=0 offense=2 defense=1 coverage=1'); Start=$true},
    @{Name='both'; Control='both'; Commands=@('6','invalid','0','6','1','3','7','1','2','6','2','5','7','2','3','2','','3','','1','','3'); Expected=@('HALFTIME_STATE team=0 offense=2 defense=1 coverage=1','HALFTIME_STATE team=1 offense=4 defense=2 coverage=2','Choose 1, 2, or 0.'); Start=$true},
    @{Name='cancel'; Control='home'; Commands=@('6','0','7','0','1','','3'); Expected=@('HALFTIME_STATE team=1 offense=0 defense=0 coverage=0'); Start=$true},
    @{Name='end'; Control='home'; Commands=@('6','3','7','2','5','3'); Expected=@('Offensive style set to TRIANGLE.','Defensive style set to PRESSURE MAN-TO-MAN.'); Start=$false},
    @{Name='computer'; Control='computer'; Commands=@('6','7','1','','3'); Expected=@('Both teams are computer controlled.'); Start=$true}
)
foreach ($case in $cases) {
    $inputFile = Join-Path $results ($case.Name + '.input.txt')
    $outputFile = Join-Path $results ($case.Name + '.output.txt')
    $errorFile = Join-Path $results ($case.Name + '.error.txt')
    [IO.File]::WriteAllLines($inputFile, $setup + $case.Commands)
    $process = Start-Process -FilePath $exe -ArgumentList '--accessible','--accessible-test','--accessible-halftime-test',('--halftime-control=' + $case.Control) -WorkingDirectory (Split-Path $exe) -WindowStyle Hidden -RedirectStandardInput $inputFile -RedirectStandardOutput $outputFile -RedirectStandardError $errorFile -PassThru
    if (-not $process.WaitForExit(15000)) { Stop-Process -Id $process.Id -Force; throw "Timeout: $outputFile" }
    $process.WaitForExit()
    $transcript = [IO.File]::ReadAllText($outputFile)
    if ($process.ExitCode -ne 0) { throw "Process failed: $errorFile" }
    foreach ($expected in ($case.Expected + @('Halftime rest applied. Temporary fatigue has been reset.','Exiting Courtside College Basketball.'))) {
        if (-not $transcript.Contains($expected)) { throw "Missing '$expected': $outputFile" }
    }
    if ($transcript.Contains('Crash the offensive boards during the last two minutes')) { throw "Halftime treated as late game: $outputFile" }
    $announcement = $transcript.IndexOf('Actual second-half lineups, after computer coaching.')
    $resume = $transcript.IndexOf('Second-half possession reached after halftime substitution.')
    if ($case.Start) {
        if ($announcement -lt 0 -or $resume -le $announcement) { throw "Missing or late final lineup announcement: $outputFile" }
        $announced = $transcript.Substring($announcement, $resume - $announcement)
        $verified = $transcript.Substring($resume)
        $pattern = '(?m)^[1-5]\. (?:First guard|Second guard|First forward|Second forward|Center): .+\r?$'
        $announcedRows = @([regex]::Matches($announced,$pattern) | ForEach-Object {$_.Value.Trim()})
        $verifiedRows = @([regex]::Matches($verified,$pattern) | ForEach-Object {$_.Value.Trim()})
        if ($announcedRows.Count -ne 10 -or $verifiedRows.Count -ne 10 -or ($announcedRows -join "`n") -cne ($verifiedRows -join "`n")) { throw "Announced lineups differ from actual second-half players: $outputFile" }
        if ($case.Name -eq 'home' -and -not $announced.Contains('5. Center: B.EDELIN,')) { throw "Human halftime substitution was lost: $outputFile" }
    } elseif ($announcement -ge 0 -or $resume -ge 0) { throw "End at halftime resumed play: $outputFile" }
    if ($case.Name -eq 'computer' -and $transcript.Contains('6. Change offensive style.')) { throw "Computer-only menu exposes strategy editing: $outputFile" }
    Write-Output ('Passed halftime case: ' + $case.Name)
}
