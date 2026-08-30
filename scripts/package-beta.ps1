[CmdletBinding()]
param(
    [string]$Version = 'Beta-1',
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$repositoryPath = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repositoryPath 'dist'
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$archiveName = "Courtside-Accessible-$Version.zip"
$archivePath = Join-Path $OutputDirectory $archiveName
$checksumPath = $archivePath + '.sha256.txt'

$files = [ordered]@{
    'bin\HELLO.exe'                              = 'HELLO.exe'
    'bin\6TM.SCX'                                = '6TM.SCX'
    'bin\7TM.SCX'                                = '7TM.SCX'
    'bin\8TM.SCX'                                = '8TM.SCX'
    'bin\9TM.SCX'                                = '9TM.SCX'
    'bin\10TM.SCX'                               = '10TM.SCX'
    'bin\11TM.SCX'                               = '11TM.SCX'
    'bin\12TM.SCX'                               = '12TM.SCX'
    'bin\13TM.SCX'                               = '13TM.SCX'
    'bin\16TM.SCX'                               = '16TM.SCX'
    'bin\DEFAULT'                                = 'DEFAULT'
    'bin\EVENTS.BOX'                             = 'EVENTS.BOX'
    'bin\whistle.mp3'                            = 'whistle.mp3'
    'bin\swish.mp3'                              = 'swish.mp3'
    'bin\backboard.mp3'                          = 'backboard.mp3'
    'bin\buzzer.mp3'                             = 'buzzer.mp3'
    'bin\search.png'                             = 'search.png'
    'bin\floppy-disk.png'                        = 'floppy-disk.png'
    'bin\LICENSE'                                = 'LICENSE'
    'bin\QB64PE.license.txt'                     = 'QB64PE.license.txt'
    'bin\Ack_UWL.txt'                            = 'Ack_UWL.txt'
    'packaging\1 Install Team Data.cmd'          = '1 Install Team Data.cmd'
    'packaging\2 Start Accessible Game.cmd'      = '2 Start Accessible Game.cmd'
    'packaging\README FIRST.txt'                 = 'README FIRST.txt'
    'packaging\BETA TESTING AND FEEDBACK.txt'    = 'BETA TESTING AND FEEDBACK.txt'
    'packaging\KNOWN ISSUES.txt'                 = 'KNOWN ISSUES.txt'
    'packaging\support\Install-TeamData.ps1'     = 'support/Install-TeamData.ps1'
}

foreach ($sourceName in $files.Keys) {
    $sourcePath = Join-Path $repositoryPath $sourceName
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Required package file is missing: $sourceName"
    }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}
if (Test-Path -LiteralPath $checksumPath) {
    Remove-Item -LiteralPath $checksumPath -Force
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fileStream = [System.IO.File]::Open($archivePath, [System.IO.FileMode]::CreateNew)
try {
    $zip = [System.IO.Compression.ZipArchive]::new($fileStream, [System.IO.Compression.ZipArchiveMode]::Create, $false)
    try {
        foreach ($sourceName in $files.Keys) {
            $sourcePath = Join-Path $repositoryPath $sourceName
            $entryName = $files[$sourceName]
            $entry = $zip.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = (Get-Item -LiteralPath $sourcePath).LastWriteTime
            $entryStream = $entry.Open()
            $sourceStream = [System.IO.File]::OpenRead($sourcePath)
            try {
                $sourceStream.CopyTo($entryStream)
            }
            finally {
                $sourceStream.Dispose()
                $entryStream.Dispose()
            }
        }
    }
    finally {
        $zip.Dispose()
    }
}
finally {
    $fileStream.Dispose()
}

$hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
[System.IO.File]::WriteAllText($checksumPath, "$hash  $archiveName`r`n", [System.Text.Encoding]::ASCII)

Write-Host "Created: $archivePath"
Write-Host "SHA256: $hash"
Write-Host "Checksum: $checksumPath"
