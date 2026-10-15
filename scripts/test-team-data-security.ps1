$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot ('..\dist\installer-security-tests-' + [guid]::NewGuid().ToString('N'))
$helper = Join-Path $PSScriptRoot '..\packaging\support\Install-TeamData.ps1'
$powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
New-Item -ItemType Directory -Path $root | Out-Null

function Test-Archive {
    param([string]$Name, [string[]]$Names, [bool]$Reject, [bool]$WrongHash = $false)
    $fixture = Join-Path $root ($Name + '-fixture')
    $destination = Join-Path $root ($Name + '-installed')
    $zip = Join-Path $root ($Name + '.zip')
    New-Item -ItemType Directory -Path $fixture,$destination | Out-Null
    foreach ($file in $Names) { Set-Content -LiteralPath (Join-Path $fixture $file) -Value 'Harmless test data' }
    Set-Content -LiteralPath (Join-Path $destination 'preserve.txt') -Value 'Keep me'
    Compress-Archive -Path (Join-Path $fixture '*') -DestinationPath $zip
    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
    if ($WrongHash) { $hash = '0' * 64 }
    $output = & $powershell -NoProfile -ExecutionPolicy Bypass -File $helper -Destination $destination -ArchivePath $zip -ExpectedSha256 $hash 2>&1 | Out-String
    if ($Reject) {
        if ($LASTEXITCODE -eq 0) { throw "$Name was unexpectedly accepted: $output" }
        if (@(Get-ChildItem -LiteralPath $destination -File).Count -ne 1) { throw "$Name installed files before rejection" }
        if ($WrongHash -and $output -notmatch 'checksum verification failed') { throw "Missing checksum error: $output" }
        if (-not $WrongHash -and $output -notmatch 'unsupported team-data filename') { throw "Missing filename error: $output" }
    } else {
        if ($LASTEXITCODE -ne 0) { throw "$Name failed: $output" }
        foreach ($file in $Names) {
            if (-not (Test-Path -LiteralPath (Join-Path $destination $file))) { throw "Missing $file" }
        }
    }
    if ((Get-Content -LiteralPath (Join-Path $destination 'preserve.txt') -Raw).Trim() -ne 'Keep me') { throw 'Existing file changed' }
    Write-Output "PASS: $Name"
}

Test-Archive 'supported-formats' @('BASK.2025','COLBBTMS.2025','BASK.2025W','COLBBTMS.2025W','BASK.1990X','COLBBTMS.1990X','BASK.AS','COLBBTMS.AS','BASK.F4','COLBBTMS.F4','BASK.F4W','COLBBTMS.F4W') $false
Test-Archive 'checksum-mismatch' @('BASK.2025','COLBBTMS.2025') $true $true
Test-Archive 'script-extensions' @('BASK.cmd','COLBBTMS.cmd','BASK.2025','COLBBTMS.2025') $true
Test-Archive 'double-extensions' @('BASK.2025.ps1','COLBBTMS.2025.ps1') $true

# Verify the pinned default against the actual official archive, without an override.
$official = Join-Path $PSScriptRoot '..\.tools\NCAA_Teams_thru2025.zip'
if (-not (Test-Path -LiteralPath $official)) { throw 'Official archive required for the pinned-checksum integration test.' }
$output = & $powershell -NoProfile -ExecutionPolicy Bypass -File $helper -Destination (Join-Path $root 'official-installed') -ArchivePath $official 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $output -notmatch 'installed successfully') { throw "Official archive failed: $output" }
Write-Output 'PASS: official archive with pinned default checksum'
