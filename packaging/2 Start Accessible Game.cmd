@echo off
setlocal
cd /d "%~dp0"
title Courtside Accessible Beta

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
pause
exit /b 1
