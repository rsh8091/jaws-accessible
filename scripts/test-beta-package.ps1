[CmdletBinding()]
param([string]$Version = 'Beta-1')

$ErrorActionPreference = 'Stop'
$repositoryPath = Split-Path -Parent $PSScriptRoot
$outputPath = Join-Path $repositoryPath 'dist'
& (Join-Path $PSScriptRoot 'package-beta.ps1') -Version $Version -OutputDirectory $outputPath

$archiveName = "Courtside-Accessible-$Version.zip"
$archivePath = Join-Path $outputPath $archiveName
$checksumPath = $archivePath + '.sha256.txt'

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    $actual = @($zip.Entries | ForEach-Object { $_.FullName } | Sort-Object)
}
finally {
    $zip.Dispose()
}

$expected = @(
    'HELLO.exe', '6TM.SCX', '7TM.SCX', '8TM.SCX', '9TM.SCX', '10TM.SCX',
    '11TM.SCX', '12TM.SCX', '13TM.SCX', '16TM.SCX', 'DEFAULT', 'EVENTS.BOX',
    'whistle.mp3', 'swish.mp3', 'backboard.mp3', 'buzzer.mp3', 'search.png',
    'floppy-disk.png', 'LICENSE', 'QB64PE.license.txt', 'Ack_UWL.txt',
    '1 Install Team Data.cmd', '2 Start Accessible Game.cmd', 'README FIRST.txt',
    'BETA TESTING AND FEEDBACK.txt', 'KNOWN ISSUES.txt',
    'support/Install-TeamData.ps1'
) | Sort-Object

$entryDifference = @(Compare-Object $expected $actual)
if ($entryDifference.Count -ne 0) {
    throw "Package file list is incorrect:`n$($entryDifference | Out-String)"
}

$launcherText = Get-Content -LiteralPath (Join-Path $repositoryPath 'packaging\2 Start Accessible Game.cmd') -Raw
if ($launcherText -notmatch [regex]::Escape('cd /d "%~dp0"') -or $launcherText -notmatch 'HELLO\.exe" --accessible') {
    throw 'The accessible launcher does not anchor itself to its folder and launch --accessible.'
}
if ($launcherText -notmatch [regex]::Escape('BASK.*') -or
    $launcherText -notmatch [regex]::Escape('COLBBTMS.*') -or
    $launcherText -notmatch 'Team data is not installed') {
    throw 'The accessible launcher does not stop with a clear message when team data is missing.'
}

$installerText = Get-Content -LiteralPath (Join-Path $repositoryPath 'packaging\1 Install Team Data.cmd') -Raw
if ($installerText -match '-Destination\s+"%~dp0"') {
    throw 'The installer CMD passes a trailing-backslash folder argument that Windows PowerShell misparses.'
}

$checksumText = (Get-Content -LiteralPath $checksumPath -Raw).Trim()
$actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($checksumText -ne "$actualHash  $archiveName") {
    throw 'The SHA256 checksum file does not match the package.'
}

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('Courtside-Package-Test-' + [guid]::NewGuid().ToString('N'))
try {
    $fixturePath = Join-Path $testRoot 'fixture'
    $installedPath = Join-Path $testRoot 'installed'
    New-Item -ItemType Directory -Path $fixturePath,$installedPath -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $fixturePath 'BASK.2025'), 'test')
    [System.IO.File]::WriteAllText((Join-Path $fixturePath 'COLBBTMS.2025'), 'test')
    $fixtureArchive = Join-Path $testRoot 'teams.zip'
    [System.IO.Compression.ZipFile]::CreateFromDirectory($fixturePath, $fixtureArchive)
    & (Join-Path $repositoryPath 'packaging\support\Install-TeamData.ps1') -Destination $installedPath -ArchivePath $fixtureArchive
    if (-not (Test-Path -LiteralPath (Join-Path $installedPath 'BASK.2025')) -or
        -not (Test-Path -LiteralPath (Join-Path $installedPath 'COLBBTMS.2025'))) {
        throw 'The team-data helper did not install a matching test season.'
    }
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}

Write-Host "PASS: $archiveName contains only the approved files."
Write-Host 'PASS: Launcher, checksum, and offline team-data installation checks succeeded.'
