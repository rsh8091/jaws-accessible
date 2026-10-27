$ErrorActionPreference = 'Stop'
$executable = (Resolve-Path (Join-Path $PSScriptRoot '..\bin\HELLO.exe')).Path
$results = Join-Path $PSScriptRoot '..\dist\free-throw-shooter-reproduction'
New-Item -ItemType Directory -Force -Path $results | Out-Null
$results = (Resolve-Path $results).Path
$setup = @('1','2025','duke','1','2003','syracuse','1','1','2','1','1','1','1','1','90','1','1')
foreach ($case in @(
    @{ Name='two-shots-control'; Scenario='ft-shooter'; Commands=@('1'); Expected='slot_player=2 original_fta=2 original_ftm=0 replacement_fta=0 replacement_ftm=0 home_score=61' },
    @{ Name='two-shots-replace'; Scenario='ft-shooter'; Commands=@('2','3','6','','1'); Expected='slot_player=5 original_fta=0 original_ftm=0 replacement_fta=2 replacement_ftm=2 home_score=63' },
    @{ Name='one-and-one-control'; Scenario='ft-shooter-one-and-one'; Commands=@('1'); Expected='slot_player=2 original_fta=1 original_ftm=0 replacement_fta=0 replacement_ftm=0 home_score=61' },
    @{ Name='one-and-one-replace'; Scenario='ft-shooter-one-and-one'; Commands=@('2','3','6','','1'); Expected='slot_player=5 original_fta=0 original_ftm=0 replacement_fta=2 replacement_ftm=2 home_score=63' }
)) {
    $inputFile = Join-Path $results ($case.Name + '.input.txt')
    $outputFile = Join-Path $results ($case.Name + '.output.txt')
    $errorFile = Join-Path $results ($case.Name + '.error.txt')
    [IO.File]::WriteAllLines($inputFile, $setup + $case.Commands + @('','','','','','','3'))
    $process = Start-Process -FilePath $executable -ArgumentList '--accessible','--accessible-test','--accessible-substitution-test',('--substitution-case=' + $case.Scenario) -WorkingDirectory (Split-Path $executable) -WindowStyle Hidden -RedirectStandardInput $inputFile -RedirectStandardOutput $outputFile -RedirectStandardError $errorFile -PassThru
    if (-not $process.WaitForExit(15000)) {
        Stop-Process -Id $process.Id -Force
        throw "Automated reproduction timed out: $outputFile"
    }
    $process.WaitForExit()
    $transcript = [IO.File]::ReadAllText($outputFile)
    if ($process.ExitCode -ne 0 -or -not $transcript.Contains('FT_REPRO_AFTER ' + $case.Expected) -or -not $transcript.Contains('FT_REPRO_COMPLETE')) {
        throw "Unexpected reproduction result: $outputFile"
    }
    Write-Output ($case.Name + ': ' + $case.Expected)
}
Write-Output 'Confirmed current defective behavior through the real menus and free-throw routines; this is a reproduction, not a fix regression test.'
