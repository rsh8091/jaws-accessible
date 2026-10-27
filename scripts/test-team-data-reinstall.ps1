$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot ('..\dist\installer-repeat-tests-' + [guid]::NewGuid().ToString('N'))
$fixture = Join-Path $root 'fixture'
$installed = Join-Path $root 'installed'
New-Item -ItemType Directory -Force $fixture,$installed | Out-Null
Set-Content (Join-Path $fixture 'BASK.2025') 'archive roster'
Set-Content (Join-Path $fixture 'COLBBTMS.2025') 'archive teams'
$zip = Join-Path $root 'teams.zip'
Compress-Archive -Path (Join-Path $fixture '*') -DestinationPath $zip
$helper = Join-Path $PSScriptRoot '..\packaging\support\Install-TeamData.ps1'
function Read-Host {
 param([string]$Prompt)
 $global:CourtsideInstallerTestPrompts++
 if($global:CourtsideInstallerTestAnswers.Count -eq 0){throw 'Unexpected installer prompt'}
 return $global:CourtsideInstallerTestAnswers.Dequeue()
}
function Set-Answers([string[]]$Values) {
 $global:CourtsideInstallerTestPrompts=0
 $global:CourtsideInstallerTestAnswers=[Collections.Generic.Queue[string]]::new()
 foreach($value in $Values){$global:CourtsideInstallerTestAnswers.Enqueue($value)}
}
Set-Answers @()
& $helper -Destination $installed -ArchivePath $zip -ExpectedSha256 (Get-FileHash $zip -Algorithm SHA256).Hash
if($global:CourtsideInstallerTestPrompts -ne 0){throw 'Fresh install prompted'}
$roster=Join-Path $installed 'BASK.2025'
$teams=Join-Path $installed 'COLBBTMS.2025'
Set-Content $roster 'user edit'
foreach($answer in @('1','99')) {
 Set-Answers @($answer)
 & $helper -Destination $installed -ArchivePath (Join-Path $root 'nonexistent.zip')
 if((Get-Content $roster -Raw).Trim() -ne 'user edit'){throw 'Existing data was overwritten'}
}
Set-Answers @('','invalid','1')
& $helper -Destination $installed -ArchivePath (Join-Path $root 'nonexistent.zip')
if($global:CourtsideInstallerTestPrompts -ne 3 -or (Get-Content $roster -Raw).Trim() -ne 'user edit'){throw 'Invalid input was not safely rejected'}
Set-Answers @('2')
& $helper -Destination $installed -ArchivePath $zip -ExpectedSha256 (Get-FileHash $zip -Algorithm SHA256).Hash
if((Get-Content $roster -Raw).Trim() -ne 'archive roster'){throw 'Explicit reinstall failed'}
# Construct a partial install separately; do not remove any user's files.
$partial=Join-Path $root 'partial'
New-Item -ItemType Directory $partial | Out-Null
Set-Content (Join-Path $partial 'COLBBTMS.2025') 'partial data'
Set-Answers @('1')
& $helper -Destination $partial -ArchivePath (Join-Path $root 'nonexistent.zip')
if(Test-Path (Join-Path $partial 'BASK.2025')){throw 'Keep unexpectedly installed data'}
Set-Answers @('2')
& $helper -Destination $partial -ArchivePath $zip -ExpectedSha256 (Get-FileHash $zip -Algorithm SHA256).Hash
if(-not (Test-Path (Join-Path $partial 'BASK.2025'))){throw 'Partial install was not repaired'}
Write-Output 'PASS: fresh install, keep, cancel, invalid input, reinstall, and partial-install repair.'
Remove-Variable -Scope Global -Name CourtsideInstallerTestPrompts,CourtsideInstallerTestAnswers
