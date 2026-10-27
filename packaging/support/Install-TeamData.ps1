[CmdletBinding()]
param(
    [string]$Destination,

    [string]$ArchiveUrl = 'https://github.com/jleonard2099/LHG_CollegeBB/releases/download/v5.26/NCAA_Teams_thru2025.zip',

    [string]$ArchivePath,

    # GitHub's published SHA-256 for the v5.26 asset above. Custom archives
    # require an explicitly supplied, independently trusted checksum.
    [ValidatePattern('^[0-9a-fA-F]{64}$')]
    [string]$ExpectedSha256 = '62a1ccd2bedd9dc89aef088b6e879f95b293b18d2ec0860d5bfd1827e223dce8'
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
        if ($_.Name -notmatch '^(BASK|COLBBTMS)\.([0-9]{4}[WX]?|AS|F4W?)$') {
            throw "The archive contains an unsupported team-data filename: $($_.Name). No files were installed."
        }
        if ($result.ContainsKey($_.Name)) {
            throw "The archive contains more than one file named $($_.Name)."
        }
        $result[$_.Name] = $_.FullName
    }
    return $result
}

try {
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    $existingTeamFiles = @(Get-ChildItem -LiteralPath $destinationPath -File | Where-Object {
        $_.Name -like 'BASK.*' -or $_.Name -like 'COLBBTMS.*'
    })
    if ($existingTeamFiles.Count -gt 0) {
        $reinstall = $false
        Write-Host 'Team-data files already exist in this folder.'
        Write-Host 'This may be a complete or partial installation.'
        Write-Host '1. Keep existing files and finish without downloading.'
        Write-Host '2. Reinstall team data. Matching files will be replaced, including any edits.'
        Write-Host '99. Cancel without changing any files.'
        do {
            $choice = Read-Host 'Enter choice'
            switch ($choice.Trim().ToLowerInvariant()) {
                { $_ -in '1', 'keep' } {
                    Write-Host 'Existing files kept. Nothing was downloaded or changed.'
                    return
                }
                { $_ -in '99', 'cancel' } {
                    Write-Host 'Installation canceled. Nothing was downloaded or changed.'
                    return
                }
                { $_ -in '2', 'reinstall' } { $reinstall = $true }
                default { Write-Host 'Choose 1 to keep, 2 to reinstall, or 99 to cancel.' }
            }
        } until ($reinstall)
    }
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

    Write-Host 'Verifying team-data download...'
    if ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash -ne $ExpectedSha256) {
        throw 'Team-data checksum verification failed. No files were installed. Download again from the official release page; if this continues, report the error.'
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
        $resolvedTemporaryPath = [IO.Path]::GetFullPath($temporaryPath)
        $temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        if (-not $resolvedTemporaryPath.StartsWith($temporaryRoot, [StringComparison]::OrdinalIgnoreCase) -or
            -not ([IO.Path]::GetFileName($resolvedTemporaryPath)).StartsWith('Courtside-Team-Data-')) { throw 'Unsafe temporary cleanup path.' }
        Remove-Item -LiteralPath $temporaryPath -Recurse -Force
    }
}
