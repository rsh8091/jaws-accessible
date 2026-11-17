param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path $Executable).Path
$root = Join-Path $PSScriptRoot ('..\dist\schedule-range-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $root | Out-Null
$root = (Resolve-Path $root).Path
$data = New-Object byte[] (52 * 4)
for ($game=0; $game -lt 4; $game++) {
    $fields = @{0=1;1=2;2=1;3=1;5=5;6=1;7=3;8=3;9=1;10=1;13=0;15=1905;16=10;17=11;18=2025}
    if ($game -eq 1) { $fields[13]=1; $fields[19]=43; $fields[20]=75 }
    foreach ($field in $fields.Keys) { [BitConverter]::GetBytes([int16]$fields[$field]).CopyTo($data,$game*52+$field*2) }
    [Text.Encoding]::ASCII.GetBytes('2025 ').CopyTo($data,$game*52+42)
    [Text.Encoding]::ASCII.GetBytes('2025 ').CopyTo($data,$game*52+47)
}
$prior = $env:COURTSIDE_SCHEDULE_TEST_FILE
$openRange = @('3','2','','6')
$setup = @('1','','1','1')
$leave = @('0','0','4')
function Run-Range($Name,[byte[]]$Bytes,[string[]]$Commands,[string[]]$Expected,[int[]]$Saved=@(),[switch]$Partial,[switch]$ReadOnly) {
    $path = Join-Path $root "$Name.SCD"
    [IO.File]::WriteAllBytes($path,$Bytes)
    $env:COURTSIDE_SCHEDULE_TEST_FILE = $path
    $inputFile = Join-Path $root "$Name.in"
    $outputFile = Join-Path $root "$Name.out"
    [IO.File]::WriteAllLines($inputFile,$Commands)
    if ($ReadOnly) { (Get-Item $path).IsReadOnly = $true }
    try {
        $arguments = @('--accessible','--accessible-test','--accessible-schedule-test')
        if (-not $Partial) { $arguments += '--accessible-turnover-diagnostic' }
        $p = Start-Process $exe -ArgumentList $arguments -WorkingDirectory (Split-Path $exe) -WindowStyle Hidden -RedirectStandardInput $inputFile -RedirectStandardOutput $outputFile -RedirectStandardError (Join-Path $root "$Name.err") -PassThru
        if (-not $p.WaitForExit(60000)) { Stop-Process -Id $p.Id -Force; throw "$Name timed out: $outputFile" }
        $p.WaitForExit()
        if ($p.ExitCode -ne 0) { throw "$Name exited $($p.ExitCode)" }
        $text = [IO.File]::ReadAllText($outputFile)
        foreach ($item in ($Expected + @('Exiting Courtside College Basketball.'))) {
            if (-not $text.Contains($item)) { throw "$Name missing '$item': $outputFile" }
        }
        $results = [regex]::Matches($text,'(?s)Range progress: game (\d+) .*?TURNOVER_DIAGNOSTIC [^\r\n]*visitor_score=(\d+) home_score=(\d+)')
        [byte[]]$expectedBytes = $Bytes.Clone()
        foreach ($game in $Saved) {
            $result = @($results | Where-Object { [int]$_.Groups[1].Value -eq $game })
            if ($result.Count -ne 1) { throw "Expected exactly one simulator result for game $game" }
            $offset = ($game-1)*52
            [BitConverter]::GetBytes([int16]1).CopyTo($expectedBytes,$offset+26)
            [BitConverter]::GetBytes([int16]$result[0].Groups[2].Value).CopyTo($expectedBytes,$offset+38)
            [BitConverter]::GetBytes([int16]$result[0].Groups[3].Value).CopyTo($expectedBytes,$offset+40)
        }
        if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($path)) -ne [Convert]::ToBase64String($expectedBytes)) { throw "$Name altered unexpected schedule records or saved the wrong score" }
        if ($Name -eq 'continue-skip' -and (($results | ForEach-Object { $_.Groups[1].Value }) -join ',') -ne '1,3') { throw 'Range did not skip completed game 2 or ran outside the range' }
        Write-Output "PASS: $Name"
    } finally { (Get-Item $path).IsReadOnly = $false }
}
try {
    Run-Range 'continue-skip' $data ($openRange + @('1','3','1') + $setup + @('1','1') + $setup + @('1','') + $leave) @('1 completed games will be skipped.','Next unplayed game: 3.','Range complete.') -Saved @(1,3)
    Run-Range 'stop-between' $data ($openRange + @('1','3','1') + $setup + @('1','0') + $leave) @('Next unplayed game: 3.') -Saved @(1)
    Run-Range 'stop-reselect' $data ($openRange + @('1','3','1') + $setup + @('1','0','','6','1','3','1') + $setup + @('1','') + $leave) @('2 completed games will be skipped.','Range complete.') -Saved @(1,3)
    Run-Range 'discard-second' $data ($openRange + @('1','3','1') + $setup + @('1','1') + $setup + @('0','') + $leave) @('Range stopped at game 3.','Earlier saved results remain.') -Saved @(1)
    Run-Range 'single-range' $data ($openRange + @('3','3','1') + $setup + @('1','') + $leave) @('Range progress: game 3','Range complete.') -Saved @(3)
    Run-Range 'completed-only' $data ($openRange + @('2','2','') + $leave) @('No unplayed games in this range.')
    Run-Range 'invalid-back' $data ($openRange + @('bad','5','1.5','3','2','5','0','0') + $leave) @('Choose a whole game number from 1 through 4.','Choose a whole game number from 3 through 4.')
    Run-Range 'cancel-confirm' $data ($openRange + @('1','3','99','4')) @('Selected range: games 1 through 3.')
    Run-Range 'cancel-number' $data ($openRange + @('cancel','4')) @('Starting game number:')
    Run-Range 'cancel-setup' $data ($openRange + @('1','3','1','0','') + $leave) @('Range stopped at game 1.')
    Run-Range 'unfinished' $data ($openRange + @('1','3','1') + $setup + @('') + $leave) @('Game unfinished.','Range stopped at game 1.') -Partial
    Run-Range 'read-only' $data ($openRange + @('1','3','1') + $setup + @('1','0','') + $leave) @('Result was not saved.','Range stopped at game 1.') -ReadOnly
    [byte[]]$long = New-Object byte[] (52*101)
    for ($game=0; $game -lt 101; $game++) { [Array]::Copy($data,52,$long,$game*52,52) }
    Run-Range 'game99' $long ($openRange + @('99','99','') + $leave) @('Selected range: games 99 through 99.','No unplayed games in this range.')
} finally { $env:COURTSIDE_SCHEDULE_TEST_FILE = $prior }
