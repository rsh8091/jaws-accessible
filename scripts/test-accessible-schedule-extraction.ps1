param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path $Executable).Path
$root = Join-Path $PSScriptRoot ('..\dist\schedule-extraction-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
$root = (Resolve-Path $root).Path
$source = Join-Path $root 'source.SCD'
$outputFile = Join-Path $root 'team.SCD'
$bytes = New-Object byte[] (52 * 4)
# Team 1 in 2025: away, home, other season (must not match), neither side.
for ($game=0; $game -lt 4; $game++) {
    $visitor = @(1,2,1,2)[$game]; $homeTeam = @(2,1,2,3)[$game]
    $fields = @{0=$visitor;1=$homeTeam;2=1;3=1;4=12;8=3;13=1;15=1905;16=10;17=11;18=2025;19=72;20=68}
    foreach ($field in $fields.Keys) { [BitConverter]::GetBytes([int16]$fields[$field]).CopyTo($bytes,$game*52+$field*2) }
    $year = if ($game -eq 2) { '2024 ' } else { '2025 ' }
    [Text.Encoding]::ASCII.GetBytes($year).CopyTo($bytes,$game*52+42)
    [Text.Encoding]::ASCII.GetBytes('2025 ').CopyTo($bytes,$game*52+47)
}
[IO.File]::WriteAllBytes($source,$bytes)
$sourceHash = (Get-FileHash $source).Hash
$teamPath = Join-Path (Split-Path $exe) 'BASK.2025'
$teamHash = (Get-FileHash $teamPath).Hash
$priorSource = $env:COURTSIDE_SCHEDULE_TEST_FILE
$priorSave = $env:COURTSIDE_SCHEDULE_SAVE_FILE
function Invoke-Case($Name,$SourcePath,$SavePath,[string[]]$Commands,[string[]]$Expected) {
    $env:COURTSIDE_SCHEDULE_TEST_FILE = $SourcePath
    $env:COURTSIDE_SCHEDULE_SAVE_FILE = $SavePath
    $inputFile = Join-Path $root "$Name.in"
    $transcriptFile = Join-Path $root "$Name.out"
    [IO.File]::WriteAllLines($inputFile,$Commands)
    $p = Start-Process $exe -ArgumentList '--accessible','--accessible-test','--accessible-schedule-test' -WorkingDirectory (Split-Path $exe) -WindowStyle Hidden -RedirectStandardInput $inputFile -RedirectStandardOutput $transcriptFile -RedirectStandardError (Join-Path $root "$Name.err") -PassThru
    if (-not $p.WaitForExit(20000)) { Stop-Process -Id $p.Id -Force; throw "$Name timed out: $transcriptFile" }
    $p.WaitForExit()
    $transcript = [IO.File]::ReadAllText($transcriptFile)
    if ($p.ExitCode -ne 0) { throw "$Name exited with $($p.ExitCode)" }
    foreach ($text in ($Expected + @('Exiting Courtside College Basketball.'))) {
        if (-not $transcript.Contains($text)) { throw "$Name missing $text : $transcriptFile" }
    }
    Write-Output "PASS: $Name"
}
try {
    (Get-Item $source).IsReadOnly = $true
    $choose = @('3','3','2','2','1')
    Invoke-Case 'extract-review' $source $outputFile ($choose + @('1','1','99','4')) @('2 games found','Saved 2 games','Games 1 through 2 of 2.')
    [byte[]]$expected = $bytes[0..103]
    [BitConverter]::GetBytes([int16]0).CopyTo($expected,8)
    [BitConverter]::GetBytes([int16]2).CopyTo($expected,16)
    [BitConverter]::GetBytes([int16]0).CopyTo($expected,60)
    [BitConverter]::GetBytes([int16]1).CopyTo($expected,68)
    if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($outputFile)) -ne [Convert]::ToBase64String($expected)) { throw 'Extracted records differ from upstream matching/settings rules' }
    $savedHash = (Get-FileHash $outputFile).Hash
    Invoke-Case 'existing-file' $source $outputFile ($choose + @('1','','0','4')) @('That file already exists.')
    Invoke-Case 'source-protected' $source $source ($choose + @('1','','0','4')) @('That file already exists.')
    Invoke-Case 'cancel-save' $source '' ($choose + @('1','0','4')) @('Schedule save canceled.')
    Invoke-Case 'cancel-team' $source $outputFile @('3','3','99','4') @('Choose the schedule team.')
    Invoke-Case 'back-team' $source $outputFile @('3','3','0','0','4') @('Choose the schedule team.')
    Invoke-Case 'cancel-picker' '' $outputFile @('3','3','0','4') @('Schedule selection canceled.')
    Invoke-Case 'no-matches' $source $outputFile @('3','3','2','2','4','','0','4') @('No games for this team and season')
    Invoke-Case 'failed-save' $source (Join-Path $root 'missing\team.SCD') ($choose + @('1','','0','4')) @('Could not save the complete team schedule.')
    Invoke-Case 'missing-source' (Join-Path $root 'absent.SCD') $outputFile @('3','3','','0','4') @('Cannot extract this schedule.')
    Invoke-Case 'extension' $source (Join-Path $root 'without-extension') ($choose + @('1','0','0','4')) @('Saved 2 games')
    if (-not (Test-Path (Join-Path $root 'without-extension.SCD'))) { throw 'Missing SCD extension' }
    if ((Get-FileHash $source).Hash -ne $sourceHash -or (Get-FileHash $teamPath).Hash -ne $teamHash -or (Get-FileHash $outputFile).Hash -ne $savedHash) { throw 'Existing data was changed' }
    Write-Output 'PASS: exact output records, original schedule, existing destination, and team data preserved.'
} finally {
    $env:COURTSIDE_SCHEDULE_TEST_FILE = $priorSource
    $env:COURTSIDE_SCHEDULE_SAVE_FILE = $priorSave
    (Get-Item $source).IsReadOnly = $false
}
