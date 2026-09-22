param([string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe'))
$ErrorActionPreference = 'Stop'
$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$resultsDirectory = Join-Path $PSScriptRoot '..\dist\setup-navigation-tests'
New-Item -ItemType Directory -Force -Path $resultsDirectory | Out-Null
$resultsDirectory = (Resolve-Path -LiteralPath $resultsDirectory).Path

function Invoke-SetupCase {
    param([string]$Name, [string[]]$Commands, [string[]]$Expected, [switch]$Canceled)
    $inputPath = Join-Path $resultsDirectory "$Name.input.txt"
    $outputPath = Join-Path $resultsDirectory "$Name.output.txt"
    $errorPath = Join-Path $resultsDirectory "$Name.error.txt"
    [IO.File]::WriteAllLines($inputPath, $Commands)
    $process = Start-Process -FilePath $executablePath -ArgumentList '--accessible', '--accessible-test', '--accessible-setup-test' -WorkingDirectory (Split-Path $executablePath) -WindowStyle Hidden -RedirectStandardInput $inputPath -RedirectStandardOutput $outputPath -RedirectStandardError $errorPath -PassThru
    if (-not $process.WaitForExit(15000)) {
        # This is the automated process started above, never an interactive game.
        Stop-Process -Id $process.Id -Force
        throw "Setup case $Name timed out. See $outputPath"
    }
    $process.WaitForExit()
    $output = [IO.File]::ReadAllText($outputPath)
    if ($process.ExitCode -ne 0) { throw "Setup case $Name exited with $($process.ExitCode). See $outputPath and $errorPath" }
    foreach ($text in $Expected) {
        if (-not $output.Contains($text)) { throw "Setup case $Name missing '$text'. See $outputPath" }
    }
    if (-not $output.Contains('Exiting Courtside College Basketball.')) { throw "Setup case $Name did not exit normally." }
    if ($Canceled) {
        if ($output.Contains('Ready for tipoff.')) { throw "Setup case $Name advanced after canceling." }
        if (-not $output.Contains('Single-game setup canceled.')) { throw "Setup case $Name did not cancel." }
    } elseif (-not $output.Contains('SETUP_TEST_COMPLETE')) {
        throw "Setup case $Name did not complete setup. See $outputPath"
    }
    Write-Host "Passed: $Name"
    return $output
}

# Only season IDs and team search terms require text. All actions below use menus.
$matchup = @('1','1','2025','1','duke','1','1','2003','1','syracuse','1')
$rosters = $matchup + @('1','2','1','1','1')
$lineup = $rosters + @('1','1')
$offense = $lineup + @('90')

$null = Invoke-SetupCase 'numbered-forward' ($offense + @('1','1','3')) @('SETUP_TEST_COMPLETE','Control: human controls home; computer controls visitor.','Shot clock: 30 seconds.')
$null = Invoke-SetupCase 'configuration-and-roster-back' ($matchup + @(
    '1','2','0','98','2','0','98','2','4','0','98','2','0','98','2','0','98','1',
    '0','1','1','0','1','1','90','2','0','98','1','3'
)) @('Location: neutral site.','Shot clock: 45 seconds.','Three-point shot: no.','Fouls to disqualify: 6.','Current style: PICK AND ROLL','SETUP_TEST_COMPLETE')

$null = Invoke-SetupCase 'team-back-and-keep' (@('1','1','2025','1','duke','1','0','98','1','2003','1','syracuse','1','0','98','1','4','1','1','1','1','1','3')) @('Visitor: DUKE (2025)','Home: SYRACUSE (2003)','Control: computer controls both teams.')
$null = Invoke-SetupCase 'search-back-invalid' (@('1','1','2025','1','duke','bad','','0','0','0','2','1','duke','1','1','2003','1','syracuse','1','1','4','1','1','1','1','1','3')) @('Choose a displayed team or navigation number.','Current season ID: 2025','SETUP_TEST_COMPLETE')

$manual = Invoke-SetupCase 'manual-lineup-back' ($lineup + @('1','1','2','0','98','3','4','5','0','98','1','2','0','0','97','98','1','3')) @('Current selection:','That player is already in the lineup.','SETUP_TEST_COMPLETE')
$edited = Invoke-SetupCase 'edit-player-preserve-other-positions' ($lineup + @('1','2','3','4','5','1','0','6','98','98','98','98','1','1','1','3')) @('Current selected lineup.','SETUP_TEST_COMPLETE')
$editedLineups = [regex]::Matches($edited, 'Home lineup:\r?\n(?:[^\r\n]*\r?\n){5}')
$before = $editedLineups[0].Value -split '\r?\n'
$after = $editedLineups[$editedLineups.Count - 1].Value -split '\r?\n'
if ($before[1] -eq $after[1] -or ($before[2..5] -join '|') -ne ($after[2..5] -join '|')) {
    throw 'Editing one player did not preserve the unaffected positions.'
}
$null = Invoke-SetupCase 'moving-player-requires-replacement' ($lineup + @('1','2','3','4','5','1','0','2','98','1','3','4','5','1','1','1','3')) @('This player occupied a later position.','No player has been selected for this position.','SETUP_TEST_COMPLETE')
$fresh = Invoke-SetupCase 'cancel-then-start-fresh' ($matchup + @('1','4','2','2','4','99') + $offense + @('1','1','3')) @('Single-game setup canceled.','SETUP_TEST_COMPLETE')
$finalSummary = $fresh.Substring($fresh.LastIndexOf('Game configuration summary'))
foreach ($expected in @('Control: human controls home; computer controls visitor.','Location: home-court advantage.','Shot clock: 30 seconds.')) {
    if (-not $finalSummary.Contains($expected)) { throw "Canceled setup leaked a setting into a new setup: $expected" }
}

# Going back to configuration must preserve a completed lineup and styles.
$preserved = Invoke-SetupCase 'preserve-lineup-and-styles' ($lineup + @(
    '1','2','3','4','5','1','2',
    '0','0','0','0','0','0','0','2','98','1','1','1','97','98','1','3'
)) @('Location: neutral site.','Current style: PICK AND ROLL','SETUP_TEST_COMPLETE')
$lineupBlocks = [regex]::Matches($preserved, 'Home lineup:\r?\n(?:[^\r\n]*\r?\n){5}')
if ($lineupBlocks.Count -lt 3 -or @($lineupBlocks | ForEach-Object Value | Select-Object -Unique).Count -ne 1) {
    throw 'Returning through configuration changed the preserved human lineup.'
}

$changedVisitor = Invoke-SetupCase 'change-one-team-preserve-other' ($lineup + @(
    '1','2','3','4','5','1','2',
    '0','0','0','0','0','0','0','0','0','2',
    '1','2025','1','michigan state','1','98','1','98','98','98','1','1','1','97','98','1','3'
)) @('Visitor: MICHIGAN ST (2025)','Team changed. Review the new lineup and strategies for this team.','Setup offense 1: PICK AND ROLL')
$homeLineups = [regex]::Matches($changedVisitor, 'Home lineup:\r?\n(?:[^\r\n]*\r?\n){5}')
if ($homeLineups.Count -lt 3 -or @($homeLineups | ForEach-Object Value | Select-Object -Unique).Count -ne 1) {
    throw 'Changing the visitor changed the home lineup.'
}
$null = Invoke-SetupCase 'changed-team-resets-dependent-choices' ($lineup + @(
    '1','2','3','4','5','1','2',
    '0','0','0','0','0','0','0','0','0','3',
    '1','2025','1','duke','1','1','98','98','98','1','1','1','97','90','98','98','3'
)) @('Home: DUKE (2025)','Choose all five players before keeping the lineup.','Setup offense 1: MOTION')
$null = Invoke-SetupCase 'new-human-team-review' ($lineup + @(
    '90','2','0','0','0','0','0','0','0','0','1','98','98','1','1','1','97','97','2','2','98','1','3'
)) @('Control: human controls both teams.','Offensive style for DUKE.','Setup offense 0: PICK AND ROLL','Setup offense 1: PICK AND ROLL')
$null = Invoke-SetupCase 'rule-change-revalidates-style' ($offense + @(
    '12','0','0','0','0','0','0','2','1','98','98','1','1','1','97','98','98','3'
)) @('Milk the clock is no longer available.','Shot clock: none.','Setup offense 1: MOTION')
$null = Invoke-SetupCase 'browse-teams' @('1','1','2025','2','26','27','28','0','99','3') @('26. Next page of teams.','27. Previous page of teams.','Enter part of a team name.') -Canceled

# Blank and invalid input must leave each selection in place. Shortcuts must
# produce the same Back and Keep behavior as their announced menu numbers.
$null = Invoke-SetupCase 'invalid-configuration-and-shortcuts' ($matchup + @(
    '1','','invalid','2','back','keep','2','','99oops','back','keep','1','','invalid','back','keep','confirm',
    '','invalid','continue','continue','auto','2','back','keep','1','3'
)) @('Current settings are unchanged.','Location: neutral site.','Setup offense 1: PICK AND ROLL')

# Every interactive level has a cancellation path; none may fall through to play.
$cancelPoints = @{
    'season-menu' = @('1')
    'season-entry' = @('1','1')
    'team-menu' = @('1','1','2025')
    'team-search' = @('1','1','2025','1')
    'team-results' = @('1','1','2025','1','duke')
    'home-season' = @('1','1','2025','1','duke','1')
    'matchup' = $matchup
    'control' = $matchup + @('1')
    'location' = $matchup + @('1','2')
    'rules' = $matchup + @('1','2','1')
    'custom-clock' = $matchup + @('1','2','1','2')
    'custom-threes' = $matchup + @('1','2','1','2','2')
    'custom-fouls' = $matchup + @('1','2','1','2','2','1')
    'summary' = $matchup + @('1','2','1','1')
    'visiting-roster' = $rosters
    'home-roster' = $rosters + @('1')
    'lineup' = $lineup
    'lineup-position' = $lineup + @('1')
    'lineup-confirm' = $lineup + @('1','2','3','4','5')
    'offense' = $offense
    'defense' = $offense + @('1')
}
foreach ($name in ($cancelPoints.Keys | Sort-Object)) {
    foreach ($cancel in @('99','cancel')) {
        $null = Invoke-SetupCase "cancel-$name-$cancel" ($cancelPoints[$name] + @($cancel,'3')) @() -Canceled
    }
}
$null = Invoke-SetupCase 'back-at-first-step' @('1','0','3') @() -Canceled
Write-Output 'Accessible setup navigation checks passed.'
