@echo off
REM Claude Trip Computer - Windows Installation Wrapper
REM Version: 0.13.6
REM
REM This batch file locates Git Bash and runs the installation script
REM

setlocal enabledelayedexpansion

echo.
echo ================================================
echo   Claude Trip Computer - Windows Installation
echo   Version 0.13.2
echo ================================================
echo.

REM Check for Git Bash in common locations
set "GITBASH="

REM Check each path individually to avoid parentheses parsing issues
if exist "C:\Program Files\Git\bin\bash.exe" (
    set "GITBASH=C:\Program Files\Git\bin\bash.exe"
    goto :found_bash
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    set "GITBASH=C:\Program Files (x86)\Git\bin\bash.exe"
    goto :found_bash
)
if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" (
    set "GITBASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
    goto :found_bash
)
if exist "C:\Git\usr\bin\bash.exe" (
    set "GITBASH=C:\Git\usr\bin\bash.exe"
    goto :found_bash
)
if exist "C:\msys64\usr\bin\bash.exe" (
    set "GITBASH=C:\msys64\usr\bin\bash.exe"
    goto :found_bash
)

:not_found
echo [ERROR] Git Bash not found
echo.
echo Git for Windows is required. Please install from:
echo   https://git-scm.com/download/win
echo.
echo After installation, run this script again.
echo.
pause
exit /b 1

:found_bash
echo [OK] Found Git Bash: %GITBASH%
echo.

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Convert Windows path to Unix path for bash
set "UNIX_PATH=%SCRIPT_DIR:\=/%"
if "!UNIX_PATH:~1,1!"==":" (
    set "DRIVE=!UNIX_PATH:~0,1!"
    set "UNIX_PATH=/!DRIVE!!UNIX_PATH:~2!"
)

REM Run the bash installation script
echo Running installation script...
echo.
"%GITBASH%" -c "cd '%UNIX_PATH%' && bash ./install.sh"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Installation failed
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ================================================
echo Installation completed successfully!
echo ================================================
echo.
echo Please restart Claude Code to activate the status line.
echo.
pause
