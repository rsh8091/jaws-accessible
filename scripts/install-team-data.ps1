param(
    [string]$Destination = (Join-Path $PSScriptRoot '..\bin')
)

$ErrorActionPreference = 'Stop'
$archiveUrl = 'https://github.com/jleonard2099/LHG_CollegeBB/releases/download/v5.26/NCAA_Teams_thru2025.zip'
$toolsDirectory = Join-Path $PSScriptRoot '..\.tools'
$archivePath = Join-Path $toolsDirectory 'NCAA_Teams_thru2025.zip'

New-Item -ItemType Directory -Force -Path $toolsDirectory, $Destination | Out-Null

if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
    Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath
}

Expand-Archive -LiteralPath $archivePath -DestinationPath $Destination -Force

$teamFiles = @(Get-ChildItem -LiteralPath $Destination -Filter 'BASK.*' -File)
$dataFiles = @(Get-ChildItem -LiteralPath $Destination -Filter 'COLBBTMS.*' -File)

if ($teamFiles.Count -eq 0 -or $teamFiles.Count -ne $dataFiles.Count) {
    throw "Team-data installation is incomplete: $($teamFiles.Count) BASK files and $($dataFiles.Count) COLBBTMS files."
}

Write-Output "Installed $($teamFiles.Count) matched team-data sets in $([IO.Path]::GetFullPath($Destination))."
