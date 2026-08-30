[CmdletBinding()]
param(
    [string]$Destination,

    [string]$ArchiveUrl = 'https://github.com/jleonard2099/LHG_CollegeBB/releases/download/v5.26/NCAA_Teams_thru2025.zip',

    [string]$ArchivePath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = Split-Path -Parent $PSScriptRoot
}
$destinationPath = [System.IO.Path]::GetFullPath($Destination)
$temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) ('Courtside-Team-Data-' + [guid]::NewGuid().ToString('N'))
$downloadedArchive = $false

function Get-TeamFileMap {
    param([string]$Root)

    $result = @{}
    Get-ChildItem -LiteralPath $Root -File -Recurse | Where-Object {
        $_.Name -like 'BASK.*' -or $_.Name -like 'COLBBTMS.*'
    } | ForEach-Object {
        if ($result.ContainsKey($_.Name)) {
            throw "The archive contains more than one file named $($_.Name)."
        }
        $result[$_.Name] = $_.FullName
    }
    return $result
}

try {
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    New-Item -ItemType Directory -Path $temporaryPath | Out-Null

    if ([string]::IsNullOrWhiteSpace($ArchivePath)) {
        $ArchivePath = Join-Path $temporaryPath 'NCAA_Teams_thru2025.zip'
        $downloadedArchive = $true
        Write-Host 'Downloading official team data. Please wait...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing -Uri $ArchiveUrl -OutFile $ArchivePath
    }
    else {
        $ArchivePath = [System.IO.Path]::GetFullPath($ArchivePath)
    }

    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
        throw "Team-data archive not found: $ArchivePath"
    }

    $expandedPath = Join-Path $temporaryPath 'expanded'
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $expandedPath -Force
    $teamFiles = Get-TeamFileMap -Root $expandedPath

    $baskNames = @($teamFiles.Keys | Where-Object { $_ -like 'BASK.*' } | Sort-Object)
    $collegeNames = @($teamFiles.Keys | Where-Object { $_ -like 'COLBBTMS.*' } | Sort-Object)
    if ($baskNames.Count -eq 0 -or $collegeNames.Count -eq 0) {
        throw 'The downloaded archive does not contain both BASK and COLBBTMS team files.'
    }

    $baskSeasons = @($baskNames | ForEach-Object { $_.Substring(5) })
    $collegeSeasons = @($collegeNames | ForEach-Object { $_.Substring(9) })
    $differences = @(Compare-Object $baskSeasons $collegeSeasons)
    if ($differences.Count -ne 0) {
        throw 'The BASK and COLBBTMS season files in the archive do not match.'
    }

    foreach ($name in $teamFiles.Keys) {
        Copy-Item -LiteralPath $teamFiles[$name] -Destination (Join-Path $destinationPath $name) -Force
    }

    Write-Host ''
    Write-Host "Team data installed successfully: $($baskNames.Count) seasons."
    Write-Host 'You may now run 2 Start Accessible Game.cmd.'
}
catch {
    Write-Host ''
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    if ($downloadedArchive) {
        Write-Host 'Check your internet connection and GitHub access, then run this installer again.'
        Write-Host ('Manual download: ' + $ArchiveUrl)
    }
    exit 1
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Recurse -Force
    }
}
