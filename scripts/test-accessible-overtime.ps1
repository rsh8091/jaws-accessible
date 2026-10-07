param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path $Executable).Path
$results = Join-Path $PSScriptRoot '..\dist\overtime-tests'
New-Item -ItemType Directory -Force $results | Out-Null
$results = (Resolve-Path $results).Path
$setup = @('1','2025','duke','1','2003','syracuse','1','1','2','1','1','confirm','continue','continue','auto','1','1')
$cases = @(
 @{Name='home'; Control='home'; Commands=@('','invalid','6','10','3','7','2','4','5','5','3','','1',''); Expected=@('OT_STATE period=1 team=1 offense=2 defense=1','B.EDELIN replaces C.FORTH as center.','only available during the last three minutes','Enter a displayed numbered choice.'); Periods=1},
 @{Name='visitor'; Control='visitor'; Commands=@('6','3','7','2','1',''); Expected=@('OT_STATE period=1 team=0 offense=2 defense=1'); Periods=1},
 @{Name='both'; Control='both'; Commands=@('6','0','4','0','6','1','3','7','2','2','1',''); Expected=@('OT_STATE period=1 team=0 offense=2','OT_STATE period=1 team=1 offense=0 defense=1','0. Back to overtime options.'); Periods=1},
 @{Name='cancel'; Control='home'; Commands=@('6','0','7','0','4','99','1',''); Expected=@('OT_STATE period=1 team=1 offense=0 defense=0','Cancel substitution and return to overtime options.'); Periods=1},
 @{Name='repeat'; Control='home'; Commands=@('6','3','1','','7','2','1',''); Expected=@('OT_STATE period=2 team=1 offense=2 defense=1','Overtime 2 will be five minutes.'); Periods=2},
 @{Name='computer'; Control='computer'; Commands=@('4','6','7','1',''); Expected=@('Both teams are computer controlled.'); Periods=1},
 @{Name='manual-end'; Control='home'; Commands=@('5'); Expected=@('Manual JAWS overtime test.','Overtime options'); Periods=0},
 @{Name='end'; Control='home'; Commands=@('5'); Expected=@('5. End the game segment before overtime.'); Periods=0}
)
foreach ($case in $cases) {
 $inputFile=Join-Path $results ($case.Name+'.input.txt')
 $outputFile=Join-Path $results ($case.Name+'.output.txt')
 $errorFile=Join-Path $results ($case.Name+'.error.txt')
 $ending = if($case.Periods -gt 0){@('','5','3')}else{@('3')}
 [IO.File]::WriteAllLines($inputFile,$setup+$case.Commands+$ending)
 $arguments=@('--accessible','--accessible-test','--accessible-overtime-test',('--overtime-control='+$case.Control))
 if($case.Name -eq 'manual-end'){$arguments=@('--accessible','--jaws-overtime-test')}
 if($case.Name -eq 'repeat'){$arguments+='--overtime-repeat'}
 $process=Start-Process $exe -ArgumentList $arguments -WorkingDirectory (Split-Path $exe) -WindowStyle Hidden -RedirectStandardInput $inputFile -RedirectStandardOutput $outputFile -RedirectStandardError $errorFile -PassThru
 if(-not $process.WaitForExit(15000)){Stop-Process -Id $process.Id -Force; throw "Timeout: $outputFile"}
 $process.WaitForExit()
 $transcript=[IO.File]::ReadAllText($outputFile)
 if($process.ExitCode -ne 0){throw "Process failed: $errorFile"}
 foreach($expected in ($case.Expected+@('The score is tied: DUKE 70, SYRACUSE 70.','Exiting Courtside College Basketball.'))){if(-not $transcript.Contains($expected)){throw "Missing '$expected': $outputFile"}}
 if([regex]::Matches($transcript,'Overtime possession reached through the original simulator.').Count -ne $case.Periods){throw "Wrong overtime count: $outputFile"}
 if([regex]::Matches($transcript,'Each team receives one additional timeout.').Count -ne [Math]::Max(1,$case.Periods)){throw "Repeated timeout grant: $outputFile"}
 if($case.Periods -gt 0){
  if(-not $transcript.Contains("Final score: DUKE 70, SYRACUSE 72.") -or -not $transcript.Contains("The game is over.")){throw "Missing final result: $outputFile"}
  $pattern='(?s)Starting overtime lineups\.(.*?)Overtime possession reached through the original simulator\.(.*?)(?=End of|$)'
  $blocks=[regex]::Matches($transcript,$pattern)
  if($blocks.Count -ne $case.Periods){throw "Missing lineup announcement: $outputFile"}
  foreach($block in $blocks){
   $rows='(?m)^[1-5]\. (?:First guard|Second guard|First forward|Second forward|Center): .+\r?$'
   $announced=@([regex]::Matches($block.Groups[1].Value,$rows)|ForEach-Object {$_.Value.Trim()})
   $actual=@([regex]::Matches($block.Groups[2].Value,$rows)|ForEach-Object {$_.Value.Trim()})
   if($announced.Count -ne 10 -or ($announced -join "`n") -cne ($actual -join "`n")){throw "Lineup mismatch: $outputFile"}
  }
 }
 if($case.Name -eq 'computer' -and $transcript.Contains('6. Change offensive style.')){throw 'Computer menu exposes coaching choices'}
 Write-Output ('Passed overtime case: '+$case.Name)
}
