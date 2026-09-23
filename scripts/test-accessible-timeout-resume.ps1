param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path $Executable).Path
$results = Join-Path $PSScriptRoot '..\dist\timeout-resume-tests'
New-Item -ItemType Directory -Force -Path $results | Out-Null
$results = (Resolve-Path $results).Path
$setup = @('1','2025','duke','1','2003','syracuse','1','1','2','1','1','1','1','1','90','1','1')
$cases = @(
    @{Name='continue-pass'; Menu=@('1'); Play='1'},
    @{Name='continue-shot'; Menu=@('1'); Play='2'},
    @{Name='cancel-sub-pass'; Menu=@('2','99','1'); Play='1'},
    @{Name='complete-sub-shot'; Menu=@('2','5','7','','1'); Play='2'},
    @{Name='back-sub-pass'; Menu=@('2','5','0','99','1'); Play='1'}
)
foreach ($case in $cases) {
    $inputPath = Join-Path $results ($case.Name + '.input.txt')
    $outputPath = Join-Path $results ($case.Name + '.output.txt')
    $errorPath = Join-Path $results ($case.Name + '.error.txt')
    # First pause: Enter. Second: invalid 1 then Enter. Third: invalid 2 then Enter.
    [IO.File]::WriteAllLines($inputPath, $setup + $case.Menu + @('','1','','2','',$case.Play,'3'))
    $process = Start-Process -FilePath $executablePath -ArgumentList '--accessible','--accessible-test','--accessible-substitution-test','--substitution-case=timeout-resume','--rest-clock=300' -WorkingDirectory (Split-Path $executablePath) -WindowStyle Hidden -RedirectStandardInput $inputPath -RedirectStandardOutput $outputPath -RedirectStandardError $errorPath -PassThru
    if (-not $process.WaitForExit(15000)) {
        Stop-Process -Id $process.Id -Force
        throw "$($case.Name) timed out. See $outputPath"
    }
    $process.WaitForExit()
    $output = [IO.File]::ReadAllText($outputPath)
    if ($process.ExitCode -ne 0) { throw "$($case.Name) exited with $($process.ExitCode). See $errorPath" }
    foreach ($expected in @('Timeout options for','Second half, 5 minutes remaining.','TIMEOUT_RESUME_PAUSE 1','TIMEOUT_RESUME_PAUSE 2','TIMEOUT_RESUME_PAUSE 3',"TIMEOUT_RESUME_PLAY $([int]$case.Play - 1)",'SUBSTITUTION_TEST_COMPLETE','Exiting Courtside College Basketball.')) {
        if (-not $output.Contains($expected)) { throw "Missing $expected. See $outputPath" }
    }
    if ($output.Contains('SUBSTITUTION_TEST_FAIL') -or $output.Contains('Accessible game segment complete.')) { throw "Unexpected game state or early exit. See $outputPath" }
    if ([regex]::Matches($output,'Press Enter to continue, or type clock or end\.').Count -ne 2) { throw "Invalid numbers did not stay at the pause. See $outputPath" }
    Write-Output "Passed: $($case.Name)"
}
