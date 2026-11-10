param(
    [string]$Executable = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$executablePath = (Resolve-Path -LiteralPath $Executable).Path
$scriptedInput = @('2', '', 'not-a-command', '3', '0', '4')
Push-Location (Split-Path -Parent $executablePath)
try {
    $transcript = $scriptedInput | & $executablePath --accessible --accessible-test 2>&1 | Out-String
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Accessible menu exited with code $LASTEXITCODE.`n$transcript"
}

$expectedText = @(
    'Accessible command-line mode.',
    'Accessibility help',
    '3. Schedules and Boxscores.',
    '4. Exit.',
    'Schedule review only in this version.',
    'Press Enter to return to the main menu:',
    'Choice not recognized.',
    'Exiting Courtside College Basketball.'
)

foreach ($expected in $expectedText) {
    if (-not $transcript.Contains($expected)) {
        throw "Accessible menu transcript did not contain: $expected`n$transcript"
    }
}

$mainMenus = [regex]::Matches($transcript, '(?s)Main menu\r?\n(.*?)Enter choice:')
if ($mainMenus.Count -eq 0) { throw 'No main menu found.' }
foreach ($menu in $mainMenus) {
    $choices = [regex]::Matches($menu.Groups[1].Value, '(?m)^(\d+)\. ([^\r\n]+)')
    if ($choices.Count -eq 0 -or $choices[$choices.Count-1].Groups[2].Value -ne 'Exit.') {
        throw 'Exit must be the last numbered main-menu option.'
    }
    for ($index=0; $index -lt $choices.Count; $index++) {
        if ([int]$choices[$index].Groups[1].Value -ne $index+1) { throw 'Main-menu numbers must be consecutive.' }
    }
}
Write-Output 'Accessible menu transcript test passed; Exit is last.'
