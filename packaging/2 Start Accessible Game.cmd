@echo off
setlocal
cd /d "%~dp0"
title Courtside Accessible

if not exist "%~dp0HELLO.exe" (
    echo ERROR: HELLO.exe is missing.
    echo Extract the complete release ZIP, then try again.
    pause
    exit /b 1
)

dir /b "%~dp0BASK.*" >nul 2>&1
if errorlevel 1 goto :team_data_missing

dir /b "%~dp0COLBBTMS.*" >nul 2>&1
if errorlevel 1 goto :team_data_missing

echo Starting Courtside in accessible mode...
echo.
"%~dp0HELLO.exe" --accessible
set "GAME_EXIT=%ERRORLEVEL%"

echo.
if not "%GAME_EXIT%"=="0" echo The game ended with error code %GAME_EXIT%.
echo The game has closed. Press any key to close this window.
pause >nul
endlocal & exit /b %GAME_EXIT%

:team_data_missing
echo ERROR: Team data is not installed.
echo Run "1 Install Team Data.cmd" first, then start the game again.
echo.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command "$ErrorActionPreference = 'Stop'; try { $shell = New-Object -ComObject WScript.Shell; $null = $shell.Popup('Team data is not installed. Run 1 Install Team Data.cmd, then start the game again.', 0, 'Courtside Accessible - Team data required', 4160); exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo Team data is not installed. Run "1 Install Team Data.cmd" first.
    set /p "ACKNOWLEDGE=Press Enter to close this window: "
)
exit /b 1
