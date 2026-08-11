param(
    [string]$Compiler = (Join-Path $PSScriptRoot '..\.tools\qb64pe\qb64pe.exe'),
    [string]$Output = (Join-Path $PSScriptRoot '..\bin\HELLO.exe')
)

$ErrorActionPreference = 'Stop'

$compilerPath = (Resolve-Path -LiteralPath $Compiler).Path
$sourceDirectory = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\src')).Path
$sourcePath = Join-Path $sourceDirectory 'HELLO.BAS'
$outputPath = [System.IO.Path]::GetFullPath($Output)

New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($outputPath)) | Out-Null

Push-Location $sourceDirectory
try {
    & $compilerPath -x $sourcePath -o $outputPath
    if ($LASTEXITCODE -ne 0) {
        throw "QB64-PE failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "QB64-PE did not create the expected executable: $outputPath"
}

$builtFile = Get-Item -LiteralPath $outputPath
$builtHash = Get-FileHash -LiteralPath $outputPath -Algorithm SHA256

Write-Output "Built $($builtFile.FullName)"
Write-Output "Size: $($builtFile.Length) bytes"
Write-Output "SHA256: $($builtHash.Hash)"
