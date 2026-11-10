param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path $Executable).Path
$root = Join-Path $PSScriptRoot ('..\dist\schedule-review-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
$root = (Resolve-Path $root).Path
$schedule = Join-Path $root 'Schedule review sample.SCD'
$bytes = New-Object byte[] (52 * 101)
for ($game=0; $game -lt 101; $game++) {
    $fields = @{0=1; 1=2; 2=1; 3=1; 5=5; 7=3; 8=3; 13=0; 15=1905; 16=10; 17=11; 18=2025}
    if ($game -eq 0) { $fields[13]=1 }
    foreach ($field in $fields.Keys) { [BitConverter]::GetBytes([int16]$fields[$field]).CopyTo($bytes, $game*52+$field*2) }
    [BitConverter]::GetBytes([int16]72).CopyTo($bytes,$game*52+38)
    [BitConverter]::GetBytes([int16]68).CopyTo($bytes,$game*52+40)
    [Text.Encoding]::ASCII.GetBytes('2025 ').CopyTo($bytes,$game*52+42)
    [Text.Encoding]::ASCII.GetBytes('2025 ').CopyTo($bytes,$game*52+47)
}
[IO.File]::WriteAllBytes($schedule,$bytes)
$hashBefore = (Get-FileHash $schedule).Hash
$teamPath = Join-Path (Split-Path $exe) 'BASK.2025'
$teamBytes = [IO.File]::ReadAllBytes($teamPath)
$visitor = [Text.Encoding]::ASCII.GetString($teamBytes,0,15).TrimEnd() -replace '^\d{2} ',''
$homeTeam = [Text.Encoding]::ASCII.GetString($teamBytes,655,15).TrimEnd() -replace '^\d{2} ',''
$teamHashBefore = (Get-FileHash $teamPath).Hash
$priorTestFile = $env:COURTSIDE_SCHEDULE_TEST_FILE

function Invoke-ReviewCase([string]$Name,[string]$File,[string[]]$InputLines,[string[]]$Expected) {
    $env:COURTSIDE_SCHEDULE_TEST_FILE = $File
    $inputPath = Join-Path $root ($Name+'.input.txt')
    $outputPath = Join-Path $root ($Name+'.output.txt')
    $errorPath = Join-Path $root ($Name+'.error.txt')
    [IO.File]::WriteAllLines($inputPath,$InputLines)
    $process = Start-Process $exe -ArgumentList '--accessible','--accessible-test','--accessible-schedule-test' -WorkingDirectory (Split-Path $exe) -WindowStyle Hidden -RedirectStandardInput $inputPath -RedirectStandardOutput $outputPath -RedirectStandardError $errorPath -PassThru
    if (-not $process.WaitForExit(20000)) {
        Stop-Process -Id $process.Id -Force
        throw "$Name timed out; see $outputPath"
    }
    $process.WaitForExit()
    $output = [IO.File]::ReadAllText($outputPath)
    if ($process.ExitCode -ne 0) { throw "$Name exited with $($process.ExitCode)" }
    foreach ($text in ($Expected + @('Exiting Courtside College Basketball.'))) {
        if (-not $output.Contains($text)) { throw "$Name missing '$text'; see $outputPath" }
    }
    if ($output.Contains('Original simulator validation.')) { throw "$Name unexpectedly started gameplay" }
    if ($Name -eq 'cancel-review' -and $output.Contains('Schedule navigation.')) { throw 'Navigation printed before the user finished reviewing the page' }
    if ($Name -like 'detail-*') {
        $details = [regex]::Matches($output, '(?s)Game detail: (\d+) of 101\.(.*?)1 or Enter for navigation choices')
        if ($details.Count -eq 0) { throw 'No individual game details were shown' }
        foreach ($detail in $details) {
            $games = [regex]::Matches($detail.Groups[2].Value, '(?m)^Game (\d+)\.')
            if ($games.Count -ne 1 -or $games[0].Groups[1].Value -ne $detail.Groups[1].Value) { throw 'Game detail included the wrong game or multiple games' }
        }
        if ($Name -eq 'detail-browse') {
            $sequence = @($details | ForEach-Object { $_.Groups[1].Value }) -join ','
            if ($sequence -ne '8,9,8,8') { throw "Unexpected detail navigation: $sequence" }
            if ([regex]::Matches($output, '(?m)^Games 6 through 10 of 101\.').Count -ne 2) { throw 'Back did not restore the original schedule page' }
        }
    }
    Write-Output "PASS: $Name"
}

try {
    (Get-Item $schedule).IsReadOnly = $true
    $pageCommands = @('3','2','','2','','1','','2')
    for ($page=0; $page -lt 20; $page++) { $pageCommands += @('','1') }
    $pageCommands += @('','1','','4','','0','0','4')
    Invoke-ReviewCase 'browse-readonly' $schedule $pageCommands @(
        'Games 1 through 5 of 101.','Games 6 through 10 of 101.','Games 96 through 100 of 101.',
        'Games 101 through 101 of 101.','This is the first page.','This is the last page.',
        "Game 1. $visitor (2025) at $homeTeam (2025).",'Date: 11/10/2025.','Time: 7:05 PM.',
        "Final score: $visitor 72, $homeTeam 68.",'Not played.')
    Invoke-ReviewCase 'detail-browse' $schedule @('3','2','','1','','3','bad','102','8','','1','','2','','3','0','0','0','4') @(
        'Game detail: 8 of 101.','Game detail: 9 of 101.','Choose a whole game number from 1 through 101.','0. Back to the schedule page.')
    Invoke-ReviewCase 'detail-first' $schedule @('3','2','','3','1','','2','','invalid','','0','0','0','4') @('This is the first game.','Choose a displayed number.')
    Invoke-ReviewCase 'detail-last' $schedule @('3','2','','3','101','','1','','99','4') @('This is the last game.')
    Invoke-ReviewCase 'detail-game99' $schedule @('3','2','','3','99','99','4') @('Game detail: 99 of 101.')
    Invoke-ReviewCase 'goto-back' $schedule @('3','2','','3','0','0','0','4') @('Games 1 through 5 of 101.')
    Invoke-ReviewCase 'cancel-picker' '' @('3','invalid','2','0','4') @('Schedule selection canceled.','Choose 2 to open a schedule')
    Invoke-ReviewCase 'cancel-review' $schedule @('3','2','99','4') @('Read-only review.')
    Invoke-ReviewCase 'review-pause-input' $schedule @('3','2','invalid','1','99','4') @('Choose 1 or press Enter for navigation choices','Schedule navigation. Games 1 through 5 of 101.')
    Invoke-ReviewCase 'return-to-setup' $schedule @('3','2','0','0','1','99','4') @('Single-game setup canceled.')
    Invoke-ReviewCase 'missing-file' (Join-Path $root 'missing.SCD') @('3','2','','0','4') @('Cannot review this schedule.')
    if (Test-Path (Join-Path $root 'missing.SCD')) { throw 'Missing schedule was created' }
    foreach ($length in @(0,53,312052)) {
        $bad = Join-Path $root ("invalid-$length.SCD")
        [IO.File]::WriteAllBytes($bad,(New-Object byte[] $length))
        Invoke-ReviewCase "invalid-size-$length" $bad @('3','2','','0','4') @('Cannot review this schedule.')
    }
    $missingTeams = Join-Path $root 'missing-teams.SCD'
    $badBytes = $bytes[0..51]
    [Text.Encoding]::ASCII.GetBytes('ZZZZZ').CopyTo($badBytes,42)
    [IO.File]::WriteAllBytes($missingTeams,$badBytes)
    Invoke-ReviewCase 'missing-team-data' $missingTeams @('3','2','99','4') @('Team unavailable','A referenced team could not be read.')
    $locked = [IO.File]::Open($schedule,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None)
    try { Invoke-ReviewCase 'locked-file' $schedule @('3','2','','0','4') @('Cannot review this schedule.') } finally { $locked.Dispose() }
    if ((Get-FileHash $schedule).Hash -ne $hashBefore -or (Get-FileHash $teamPath).Hash -ne $teamHashBefore) { throw 'Schedule review changed input files' }
    Write-Output "PASS: schedule and team files unchanged. Manual picker fixture: $schedule"
} finally {
    $env:COURTSIDE_SCHEDULE_TEST_FILE = $priorTestFile
    (Get-Item $schedule).IsReadOnly = $false
}
