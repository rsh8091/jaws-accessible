param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = [System.Collections.Generic.List[string]]::new()
@(
    '1', '2025', 'duke', '1', '2003', 'syracuse', '1', '1',
    '2', '1', '1', 'confirm', 'continue', 'continue', 'auto', '1', '3'
) | ForEach-Object { $scriptedInput.Add($_) }

# Two is a valid second-player pass target and a two-point-shot choice.
# Extra entries safely cover random original-engine pass prompts.
1..40 | ForEach-Object { $scriptedInput.Add('2') }
$scriptedInput.Add('3')
# Surplus shot choices can open Help after the engine segment finishes.
# One Exit can be consumed by Help's Enter pause; the next exits the menu.
$scriptedInput.Add('3')

$results = Join-Path $PSScriptRoot '..\dist\human-vs-computer-test'
New-Item -ItemType Directory -Force -Path $results | Out-Null
$results = (Resolve-Path $results).Path
$inputFile = Join-Path $results 'input.txt'
$outputFile = Join-Path $results 'output.txt'
$errorFile = Join-Path $results 'error.txt'
[IO.File]::WriteAllLines($inputFile, $scriptedInput)
$process = Start-Process -FilePath $executablePath -ArgumentList '--accessible','--accessible-test' -WorkingDirectory (Split-Path $executablePath) -WindowStyle Hidden -RedirectStandardInput $inputFile -RedirectStandardOutput $outputFile -RedirectStandardError $errorFile -PassThru
if (-not $process.WaitForExit(30000)) {
    Stop-Process -Id $process.Id -Force
    throw "Human-versus-computer test timed out: $outputFile"
}
$process.WaitForExit()
$transcript = [IO.File]::ReadAllText($outputFile)

if ($process.ExitCode -ne 0) {
    throw "Accessible human-versus-computer transcript exited with code $($process.ExitCode).`n$transcript"
}

$expectedText = @(
    'Control: human controls home; computer controls visitor.',
    'The original game engine will play one possession for each team.',
    'Computer play runs continuously. Your team pauses when a decision is required.',
    'Possession 1 of 2:',
    'Score:',
    'Offensive strategy:',
    'is running',
    'Defensive strategy:',
    'Offensive choices',
    'Your team, SYRACUSE, is on offense.',
    'Shot clock:',
    'seconds remaining.',
    'shot chance:',
    'percent.',
    'Current situation:',
    '1. Pass.',
    '2. Attempt a two-point shot.',
    '3. Attempt a three-point shot.',
    '5. Hear score, clock, and possession.',
    '6. Hear lineup condition.',
    'Offensive style for SYRACUSE.',
    'Offensive style set to MOTION.',
    'Defensive style for SYRACUSE.',
    'Defensive style set to 2-3 ZONE (PASSIVE).',
    'Defensive strategy: SYRACUSE is running 2-3 ZONE (PASSIVE).',
    'Original simulator validation complete.',
    'Exiting Courtside College Basketball.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible human-versus-computer transcript did not contain: $expected`n$transcript"
    }
}

# The engine extends this segment if turnovers prevent a human decision in the
# first two possessions. The menu assertions above still require that decision.
$completion = [regex]::Match($transcript, '(?m)^(\d+) original-simulator possessions completed\.')
if (-not $completion.Success -or [int]$completion.Groups[1].Value -lt 2) {
    throw "Accessible human-versus-computer segment did not finish at least two possessions.`n$transcript"
}

if ($transcript.Contains('SHOT %')) {
    throw 'Legacy fixed-position shot percentage leaked into accessible narration.'
}

Write-Output 'Accessible human-versus-computer transcript test passed.'
