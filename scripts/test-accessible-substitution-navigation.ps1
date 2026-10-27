param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$resultsDirectory = Join-Path $PSScriptRoot '..\dist\substitution-navigation-tests'
New-Item -ItemType Directory -Force -Path $resultsDirectory | Out-Null
$resultsDirectory = (Resolve-Path $resultsDirectory).Path
$setup = @('1','2025','duke','1','2003','syracuse','1','1','2','1','1','1','1','1','90','1','1')

function Invoke-SubstitutionCase {
    param([string]$Name, [string]$Scenario, [string[]]$Commands,
        [string]$HomeLineup = '0,1,2,3,4', [string]$Visitor = '0,1,2,3,4',
        [string[]]$Expected = @(), [int]$Replacements = 0,
        [int]$BenchSeconds = 120, [int]$Fatigue = -5, [int]$GameSeconds = 135, [int]$RecoveredFatigue = -1)
    $inputPath = Join-Path $resultsDirectory "$Name.input.txt"
    $outputPath = Join-Path $resultsDirectory "$Name.output.txt"
    $errorPath = Join-Path $resultsDirectory "$Name.error.txt"
    [IO.File]::WriteAllLines($inputPath, $setup + $Commands + @('3'))
    $process = Start-Process -FilePath $executablePath -ArgumentList '--accessible','--accessible-test','--accessible-substitution-test',"--substitution-case=$Scenario","--rest-seconds=$BenchSeconds","--rest-fatigue=$Fatigue","--rest-clock=$GameSeconds" -WorkingDirectory (Split-Path $executablePath) -WindowStyle Hidden -RedirectStandardInput $inputPath -RedirectStandardOutput $outputPath -RedirectStandardError $errorPath -PassThru
    if (-not $process.WaitForExit(15000)) {
        Stop-Process -Id $process.Id -Force # Only this automated test process.
        throw "$Name timed out. See $outputPath"
    }
    $process.WaitForExit()
    $output = [IO.File]::ReadAllText($outputPath)
    if ($process.ExitCode -ne 0) { throw "$Name exited with $($process.ExitCode). See $errorPath" }
    foreach ($text in (@("SUBSTITUTION_TEST_LINEUP 0: $Visitor", "SUBSTITUTION_TEST_LINEUP 1: $HomeLineup", 'SUBSTITUTION_TEST_COMPLETE', 'Exiting Courtside College Basketball.') + $Expected)) {
        if (-not $output.Contains($text)) { throw "$Name missing '$text'. See $outputPath" }
    }
    if ($output.Contains('SUBSTITUTION_TEST_FAIL')) { throw "$Name changed game state unexpectedly. See $outputPath" }
    if ([regex]::Matches($output, ' replaces (?:Starter \d|Reserve (?:guard|center)) as ').Count -ne $Replacements) { throw "$Name made an unexpected number of substitutions. See $outputPath" }
    # Check every practice player: navigating must not restart a bench timer or
    # award recovery, and a completed substitution must affect only its players.
    if ($Replacements -le 1) {
        $lineups = @($Visitor, $HomeLineup)
        foreach ($team in 0..1) {
            $onCourt = @($lineups[$team].Split(',') | ForEach-Object { [int]$_ })
            foreach ($player in 0..8) {
                $expectedTime = $GameSeconds + $BenchSeconds
                $expectedFatigue = $Fatigue
                if ($player -lt 5 -and $player -notin $onCourt) { $expectedTime = $GameSeconds }
                if ($player -ge 5 -and $player -in $onCourt) { $expectedFatigue = $RecoveredFatigue }
                $state = "SUBSTITUTION_TEST_REST $team,$player fatigue=$expectedFatigue benched=$expectedTime"
                if (-not $output.Contains($state)) { throw "$Name incorrect rest state: expected '$state'. See $outputPath" }
            }
        }
    }
    Write-Output "Passed: $Name"
}

foreach ($scenario in @('timeout','dead-ball')) {
    foreach ($cancel in @('99','cancel')) {
        Invoke-SubstitutionCase "$scenario-cancel-position-$cancel" $scenario @('2',$cancel,'7')
        Invoke-SubstitutionCase "$scenario-cancel-substitute-$cancel" $scenario @('2','5',$cancel,'7')
    }
    foreach ($back in @('0','back')) {
        Invoke-SubstitutionCase "$scenario-back-position-$back" $scenario @('2',$back,'7')
        Invoke-SubstitutionCase "$scenario-back-reselect-$back" $scenario @('2','5',$back,'1','6','','7') -HomeLineup '5,1,2,3,4' -Replacements 1 -Expected @('Reserve guard replaces Starter 1 as first guard.')
        Invoke-SubstitutionCase "$scenario-back-cancel-$back" $scenario @('2','5',$back,'99','7')
    }
    Invoke-SubstitutionCase "$scenario-invalid-position" $scenario @('2','','invalid','6','1x','99','7') -Expected @('Your lineup is unchanged.')
    Invoke-SubstitutionCase "$scenario-invalid-substitute" $scenario @('2','5','','invalid','1','8','9','10','15','7x','7','','7') -HomeLineup '0,1,2,3,6' -Replacements 1 -Expected @('That player is not an available substitute.','Reserve center replaces Starter 5 as center.')
}

foreach ($back in @('0','back')) {
    Invoke-SubstitutionCase "halftime-back-to-team-$back" 'halftime' @('4','1',$back,'2','5','7','5') -HomeLineup '0,1,2,3,6' -Replacements 1 -Expected @('0. Back to team selection.')
    Invoke-SubstitutionCase "halftime-back-to-position-$back" 'halftime' @('4','1','5',$back,'1','6','5') -Visitor '5,1,2,3,4' -Replacements 1
    Invoke-SubstitutionCase "halftime-back-to-options-$back" 'halftime' @('4',$back,'5')
}
foreach ($cancel in @('99','cancel')) {
    Invoke-SubstitutionCase "halftime-cancel-team-$cancel" 'halftime' @('4',$cancel,'5')
    Invoke-SubstitutionCase "halftime-cancel-position-$cancel" 'halftime' @('4','1',$cancel,'5')
    Invoke-SubstitutionCase "halftime-cancel-substitute-$cancel" 'halftime' @('4','1','5',$cancel,'5')
}
Invoke-SubstitutionCase 'halftime-invalid-team' 'halftime' @('4','','invalid','3','99','5') -Expected @('Choose a displayed team, 0 for Back, or 99 to cancel.')
Invoke-SubstitutionCase 'mandatory-foul-out' 'foul-out' @('0','back','99','cancel','','invalid','1','5','8','9','10','15','7x','7','') -HomeLineup '0,1,2,3,6' -Replacements 1 -Expected @('A valid replacement is required before play can resume. Back and Cancel are unavailable.')
Invoke-SubstitutionCase 'empty-bench' 'empty' @('2','5','6','7','0','5','99','7') -Expected @('No eligible substitutes are available. Choose Back or Cancel.')
foreach ($case in @(
    @{Name='rest-zero'; Seconds=0; Clock=135; Fatigue=-5; Result=-5},
    @{Name='rest-exactly-one-minute'; Seconds=60; Clock=30; Fatigue=-5; Result=-5},
    @{Name='rest-late-one-minute'; Seconds=61; Clock=30; Fatigue=-5; Result=-4},
    @{Name='rest-early-one-minute'; Seconds=61; Clock=135; Fatigue=-5; Result=-5},
    @{Name='rest-stored-clock-119'; Seconds=89; Clock=30; Fatigue=-5; Result=-4},
    @{Name='rest-stored-clock-120'; Seconds=90; Clock=30; Fatigue=-5; Result=-5},
    @{Name='rest-under-two-minutes'; Seconds=119; Clock=135; Fatigue=-5; Result=-5},
    @{Name='rest-exactly-two-minutes'; Seconds=120; Clock=135; Fatigue=-5; Result=-1},
    @{Name='rest-recovery-capped'; Seconds=180; Clock=135; Fatigue=-2; Result=0}
)) {
    Invoke-SubstitutionCase $case.Name 'dead-ball' @('2','5','7','','7') -HomeLineup '0,1,2,3,6' -Replacements 1 -BenchSeconds $case.Seconds -GameSeconds $case.Clock -Fatigue $case.Fatigue -RecoveredFatigue $case.Result
}
Invoke-SubstitutionCase 'return-without-rest' 'dead-ball' @('2','5','7','','2','5','5','','7') -Replacements 2 -Expected @(
    'SUBSTITUTION_TEST_REST 1,4 fatigue=-5 benched=135',
    'SUBSTITUTION_TEST_REST 1,6 fatigue=-1 benched=135'
)
Invoke-SubstitutionCase 'no-repeated-recovery' 'dead-ball' @('2','5','7','','2','5','5','','2','5','7','','7') -HomeLineup '0,1,2,3,6' -Replacements 3 -Expected @(
    'SUBSTITUTION_TEST_REST 1,4 fatigue=-5 benched=135',
    'SUBSTITUTION_TEST_REST 1,6 fatigue=-1 benched=135'
)
Write-Output 'Accessible substitution navigation checks passed.'
