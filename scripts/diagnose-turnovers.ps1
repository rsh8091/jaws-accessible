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
    })
}

$results | Format-Table -AutoSize
$summary = $results | Measure-Object -Property CombinedTurnovers -Average -Minimum -Maximum
Write-Output ("Combined turnover summary across {0} games: average {1:N1}, minimum {2}, maximum {3}." -f $Runs, $summary.Average, $summary.Minimum, $summary.Maximum)
