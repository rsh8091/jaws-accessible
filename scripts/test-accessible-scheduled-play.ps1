param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path $Executable).Path
$root = Join-Path $PSScriptRoot ('..\dist\scheduled-play-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $root | Out-Null
$root = (Resolve-Path $root).Path
$original = New-Object byte[] (52 * 3)
for ($game=0; $game -lt 3; $game++) {
    $fields = @{0=1;1=2;2=1;3=1;4=12;5=5;6=0;7=2;8=3;9=1;10=0;13=0;14=1;15=1905;16=10;17=11;18=2025}
    foreach ($field in $fields.Keys) { [BitConverter]::GetBytes([int16]$fields[$field]).CopyTo($original,$game*52+$field*2) }
    [Text.Encoding]::ASCII.GetBytes('2025 ').CopyTo($original,$game*52+42)
    [Text.Encoding]::ASCII.GetBytes('2025 ').CopyTo($original,$game*52+47)
}
$prior = $env:COURTSIDE_SCHEDULE_TEST_FILE
$openGame = @('3','2','','3','2','','4')
$startGame = $openGame + @('1','','1','1')
$leave = @('0','0','0','4')
function Run-Case($Name,[byte[]]$Data,[string[]]$Commands,[string[]]$Expected,[switch]$Full,[switch]$ReadOnly,[string[]]$ExtraArgs=@(),[switch]$ResetExpected) {
    $path = Join-Path $root "$Name.SCD"
    [IO.File]::WriteAllBytes($path,$Data)
    $env:COURTSIDE_SCHEDULE_TEST_FILE = $path
    $inputFile = Join-Path $root "$Name.in"
    $outputFile = Join-Path $root "$Name.out"
    [IO.File]::WriteAllLines($inputFile,$Commands)
    if ($ReadOnly) { (Get-Item $path).IsReadOnly = $true }
    try {
        $arguments = @('--accessible','--accessible-test','--accessible-schedule-test')
        $arguments += $ExtraArgs
        if ($Full) { $arguments += '--accessible-turnover-diagnostic' }
        $p = Start-Process $exe -ArgumentList $arguments -WorkingDirectory (Split-Path $exe) -WindowStyle Hidden -RedirectStandardInput $inputFile -RedirectStandardOutput $outputFile -RedirectStandardError (Join-Path $root "$Name.err") -PassThru
        if (-not $p.WaitForExit(60000)) { Stop-Process -Id $p.Id -Force; throw "$Name timed out: $outputFile" }
        $p.WaitForExit()
        if ($p.ExitCode -ne 0) { throw "$Name exited $($p.ExitCode)" }
        $text = [IO.File]::ReadAllText($outputFile)
        foreach ($item in ($Expected + @('Exiting Courtside College Basketball.'))) {
            if (-not $text.Contains($item)) { throw "$Name missing '$item': $outputFile" }
        }
        $actual = [IO.File]::ReadAllBytes($path)
        if ($Name -eq 'complete' -or $Name -eq 'reset-play') {
            $result = [regex]::Match($text,'TURNOVER_DIAGNOSTIC .*visitor_score=(\d+) home_score=(\d+)')
            if (-not $result.Success) { throw 'No real simulator final score' }
            [byte[]]$expectedBytes = $Data.Clone()
            if ($ResetExpected) { for ($offset=26; $offset -lt $expectedBytes.Length; $offset+=52) { [BitConverter]::GetBytes([int16]0).CopyTo($expectedBytes,$offset) } }
            [BitConverter]::GetBytes([int16]1).CopyTo($expectedBytes,52+26)
            [BitConverter]::GetBytes([int16]$result.Groups[1].Value).CopyTo($expectedBytes,52+38)
            [BitConverter]::GetBytes([int16]$result.Groups[2].Value).CopyTo($expectedBytes,52+40)
            if ([Convert]::ToBase64String($actual) -ne [Convert]::ToBase64String($expectedBytes)) { throw 'Saved bytes changed more than the selected result or did not match final score' }
        } elseif ($ResetExpected) {
            [byte[]]$expectedBytes = $Data.Clone()
            for ($offset=26; $offset -lt $expectedBytes.Length; $offset+=52) { [BitConverter]::GetBytes([int16]0).CopyTo($expectedBytes,$offset) }
            if ([Convert]::ToBase64String($actual) -ne [Convert]::ToBase64String($expectedBytes)) { throw "$Name changed more than completion flags" }
        } elseif ([Convert]::ToBase64String($actual) -ne [Convert]::ToBase64String($Data)) { throw "$Name changed the schedule" }
        Write-Output "PASS: $Name"
    } finally { (Get-Item $path).IsReadOnly = $false }
}
try {
    [byte[]]$historical = $original.Clone()
    for ($offset=0; $offset -lt $historical.Length; $offset+=52) {
        [BitConverter]::GetBytes([int16]1).CopyTo($historical,$offset+26)
        [BitConverter]::GetBytes([int16]43).CopyTo($historical,$offset+38)
        [BitConverter]::GetBytes([int16]75).CopyTo($historical,$offset+40)
    }
    $resetMenu = @('3','2','','5')
    Run-Case 'reset-confirm' $historical ($resetMenu + @('bad','1','','','3','2','','99','4')) @('Reset saved. All games are now unplayed.','4. Play this game.','Choose a displayed number.') -ResetExpected
    Run-Case 'reset-back' $historical ($resetMenu + @('0','0','0','4')) @('1. Confirm reset and save.')
    Run-Case 'reset-cancel' $historical ($resetMenu + @('99','4')) @('1. Confirm reset and save.')
    Run-Case 'reset-readonly' $historical ($resetMenu + @('1','','0','0','4')) @('Could not confirm the reset was saved.') -ReadOnly
    Run-Case 'reset-play' $historical ($resetMenu + @('1','','','3','2','','4','1','','1','1','1','') + $leave) @('Reset saved.','Completed result saved to the schedule.') -ResetExpected -Full
    Run-Case 'cancel-setup' $original ($openGame + @('0','') + $leave) @('Scheduled game canceled.')
    Run-Case 'cancel-main' $original ($openGame + @('99','1','0','4')) @('Scheduled game canceled.','Single-game setup')
    Run-Case 'unfinished' $original ($startGame + @('') + $leave) @('Game unfinished. The schedule is unchanged.')
    Run-Case 'complete' $original ($startGame + @('1','') + $leave) @('Completed result saved to the schedule.','Final score:') -Full
    Run-Case 'discard' $original ($startGame + @('0','') + $leave) @('Result not saved.') -Full
    Run-Case 'read-only' $original ($startGame + @('1','0','') + $leave) @('Result was not saved.') -Full -ReadOnly
    [byte[]]$completed = $original.Clone()
    [BitConverter]::GetBytes([int16]1).CopyTo($completed,52+26)
    Run-Case 'already-completed' $completed ($openGame + @('') + $leave) @('This game is already completed')
    [byte[]]$missing = $original.Clone()
    [Text.Encoding]::ASCII.GetBytes('ZZZZZ').CopyTo($missing,52+42)
    Run-Case 'missing-team' $missing ($openGame + @('') + $leave) @('Cannot play this game.')
    [byte[]]$invalid = $original.Clone()
    [BitConverter]::GetBytes([int16]99).CopyTo($invalid,52+14)
    Run-Case 'invalid-rules' $invalid ($openGame + @('') + $leave) @('Cannot play this game.')
    [byte[]]$human = $original.Clone()
    [BitConverter]::GetBytes([int16]1).CopyTo($human,52+16)
    Run-Case 'human-halftime-stop' $human ($openGame + @('1','','1','90','1','1','1','5','') + $leave) @('Control: human controls home','Halftime options','Game unfinished.') -ExtraArgs @('--accessible-halftime-test')
    $humanSetup = @('1','','1','90','1','1','1')
    $shots = @(1..40 | ForEach-Object { '2' })
    Run-Case 'human-select-shots' $human ($openGame + $humanSetup + $shots + @('99','4')) @('Current human role: coach only','Human role: coach and select shots.','1. Pass.','2. Attempt a two-point shot.','Game unfinished.')
    Run-Case 'human-keep-coach' $human ($openGame + @('98','','1','90','1','1','1','5','') + $leave) @('Human role: coach only; the computer selects shots.','Game unfinished.') -ExtraArgs @('--accessible-halftime-test')
    [byte[]]$manual = $human.Clone()
    [BitConverter]::GetBytes([int16]0).CopyTo($manual,52+18)
    Run-Case 'human-choose-coach' $manual ($openGame + @('2','','1','90','1','1','1','5','') + $leave) @('Current human role: coach and select shots.','Human role: coach only; the computer selects shots.','Game unfinished.') -ExtraArgs @('--accessible-halftime-test')
} finally { $env:COURTSIDE_SCHEDULE_TEST_FILE = $prior }
