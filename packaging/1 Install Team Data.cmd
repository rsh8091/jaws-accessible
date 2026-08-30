@echo off
setlocal
cd /d "%~dp0"
title Courtside - Install Team Data

echo Courtside Accessible Beta - Team Data Installer
echo.
echo This downloads the official team-data archive and installs it in this folder.
echo An internet connection is required.
echo.

if not exist "%~dp0support\Install-TeamData.ps1" (
    echo ERROR: The installer helper is missing.
    echo Extract the complete release ZIP, then try again.
    pause
    exit /b 1
)

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0support\Install-TeamData.ps1"
set "INSTALL_EXIT=%ERRORLEVEL%"

echo.
if not "%INSTALL_EXIT%"=="0" echo Installation did not complete. Read the error above for details.
pause
endlocal & exit /b %INSTALL_EXIT%
