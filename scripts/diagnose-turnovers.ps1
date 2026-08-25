param(
    [int]$Runs = 20,
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'
if ($Runs -lt 1) { throw 'Runs must be at least 1.' }
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$results = [System.Collections.Generic.List[object]]::new()

for ($run = 1; $run -le $Runs; $run++) {
    $scriptedInput = @(
        '1', '1999', 'syracuse', '1', '1999', 'pitt', '1', '1',
        '4', '1', '1', 'confirm', 'continue', 'continue', '3'
    )

    Push-Location (Split-Path -Parent $executablePath)
    try {
        $transcript = $scriptedInput | & $executablePath --accessible --accessible-test --accessible-turnover-diagnostic 2>&1 | Out-String
    }
    finally {
        Pop-Location
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Turnover diagnostic run $run exited with code $LASTEXITCODE.`n$transcript"
    }

    $match = [regex]::Match($transcript, 'TURNOVER_DIAGNOSTIC visitor=(\d+) home=(\d+) possessions=(\d+) visitor_score=(\d+) home_score=(\d+)')
    if (-not $match.Success) {
        throw "Turnover diagnostic run $run did not produce its result line.`n$transcript"
    }

    $detailMatches = [regex]::Matches($transcript, 'TURNOVER_DETAIL team=(\d+) direct=(\d+) steals=(\d+) offensive_fouls=(\d+) shot_clock=(\d+) inbound=(\d+) goaltend=(\d+) held_ball=(\d+) checks=(\d+) checks_after_first_pass=(\d+) max_passes=(\d+) average_threshold=(\d+) motion_pressure_checks=(\d+) motion_pressure_turnovers=(\d+)')
    if ($detailMatches.Count -ne 2) {
        throw "Turnover diagnostic run $run did not produce two detail lines.`n$transcript"
    }
    $detail = @{}
    foreach ($detailMatch in $detailMatches) {
        $detail[[int]$detailMatch.Groups[1].Value] = $detailMatch
    }

    $visitorTurnovers = [int]$match.Groups[1].Value
    $homeTurnovers = [int]$match.Groups[2].Value
    $results.Add([pscustomobject]@{
        Run = $run
        SyracuseTurnovers = $visitorTurnovers
        PittTurnovers = $homeTurnovers
        CombinedTurnovers = $visitorTurnovers + $homeTurnovers
        Possessions = [int]$match.Groups[3].Value
        SyracuseScore = [int]$match.Groups[4].Value
        PittScore = [int]$match.Groups[5].Value
        Direct = [int]$detail[0].Groups[2].Value + [int]$detail[1].Groups[2].Value
        Steals = [int]$detail[0].Groups[3].Value + [int]$detail[1].Groups[3].Value
        OffensiveFouls = [int]$detail[0].Groups[4].Value + [int]$detail[1].Groups[4].Value
        Violations = [int]$detail[0].Groups[5].Value + [int]$detail[1].Groups[5].Value + [int]$detail[0].Groups[6].Value + [int]$detail[1].Groups[6].Value
        Goaltends = [int]$detail[0].Groups[7].Value + [int]$detail[1].Groups[7].Value
        HeldBalls = [int]$detail[0].Groups[8].Value + [int]$detail[1].Groups[8].Value
        TurnoverChecks = [int]$detail[0].Groups[9].Value + [int]$detail[1].Groups[9].Value
        ChecksAfterFirstPass = [int]$detail[0].Groups[10].Value + [int]$detail[1].Groups[10].Value
        MaxPasses = [Math]::Max([int]$detail[0].Groups[11].Value, [int]$detail[1].Groups[11].Value)
        MotionPressureChecks = [int]$detail[0].Groups[13].Value + [int]$detail[1].Groups[13].Value
        MotionPressureTurnovers = [int]$detail[0].Groups[14].Value + [int]$detail[1].Groups[14].Value
    })
}

$results | Format-Table Run, SyracuseTurnovers, PittTurnovers, CombinedTurnovers, Possessions, Direct, Steals, OffensiveFouls, Violations, Goaltends, HeldBalls, TurnoverChecks, ChecksAfterFirstPass, MaxPasses -AutoSize
$summary = $results | Measure-Object -Property CombinedTurnovers -Average -Minimum -Maximum
Write-Output ("Combined turnover summary across {0} games: average {1:N1}, minimum {2}, maximum {3}." -f $Runs, $summary.Average, $summary.Minimum, $summary.Maximum)
$directSummary = $results | Measure-Object -Property Direct -Average
$stealSummary = $results | Measure-Object -Property Steals -Average
$checkSummary = $results | Measure-Object -Property TurnoverChecks -Average
$repeatCheckSummary = $results | Measure-Object -Property ChecksAfterFirstPass -Average
Write-Output ("Average sources per game: direct {0:N1}, steals {1:N1}." -f $directSummary.Average, $stealSummary.Average)
Write-Output ("Average turnover checks per game: {0:N1}; after the first pass: {1:N1}." -f $checkSummary.Average, $repeatCheckSummary.Average)
$motionPressureChecks = ($results | Measure-Object -Property MotionPressureChecks -Sum).Sum
$motionPressureTurnovers = ($results | Measure-Object -Property MotionPressureTurnovers -Sum).Sum
if ($motionPressureChecks -gt 0) {
    Write-Output ("Motion-versus-pressure observations: {0} checks and {1} turnovers ({2:P1} turnovers per check)." -f $motionPressureChecks, $motionPressureTurnovers, ($motionPressureTurnovers / $motionPressureChecks))
}
