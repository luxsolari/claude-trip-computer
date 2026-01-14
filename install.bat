@echo off
REM Claude Trip Computer - Windows Installation Wrapper
REM Version: 0.13.2
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

REM Check each standard location individually
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

REM Try to find bash.exe in PATH
echo Searching for Git Bash in system PATH...
for /f "delims=" %%i in ('where bash.exe 2^>nul') do (
    set "GITBASH=%%i"
    goto :found_bash
)

REM Scan common installation directories
echo Not found in PATH. Scanning common directories...
for %%d in (
    "C:\Git"
    "C:\Tools\Git"
    "C:\Program Files\Git"
    "C:\Program Files (x86)\Git"
    "%USERPROFILE%\scoop\apps\git"
    "%ProgramData%\chocolatey\lib\git"
    "C:\msys64"
    "C:\cygwin64"
) do (
    if exist "%%~d\bin\bash.exe" (
        set "GITBASH=%%~d\bin\bash.exe"
        echo Found at: %%~d\bin\bash.exe
        goto :found_bash
    )
    if exist "%%~d\usr\bin\bash.exe" (
        set "GITBASH=%%~d\usr\bin\bash.exe"
        echo Found at: %%~d\usr\bin\bash.exe
        goto :found_bash
    )
)

:not_found
echo [ERROR] Git Bash not found
echo.
echo Checked:
echo   - Standard Program Files locations
echo   - System PATH
echo   - Common package manager locations (scoop, chocolatey)
echo   - MSYS2/Cygwin locations
echo.
echo Please enter the full path to bash.exe, or press Ctrl+C to cancel.
echo Example: C:\Git\bin\bash.exe
echo.
set /p "GITBASH=Path to bash.exe: "

if not exist "!GITBASH!" (
    echo.
    echo [ERROR] File not found: !GITBASH!
    echo.
    pause
    exit /b 1
)

:found_bash
echo [OK] Found Git Bash: !GITBASH!
echo.

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Convert Windows path to Unix path for bash
set "UNIX_PATH=%SCRIPT_DIR:\=/%"
if "!UNIX_PATH:~1,1!"==":" (
    set "DRIVE=!UNIX_PATH:~0,1!"
    REM Convert drive letter to lowercase for Git Bash
    set "DRIVE=!DRIVE:A=a!"
    set "DRIVE=!DRIVE:B=b!"
    set "DRIVE=!DRIVE:C=c!"
    set "DRIVE=!DRIVE:D=d!"
    set "DRIVE=!DRIVE:E=e!"
    set "DRIVE=!DRIVE:F=f!"
    set "DRIVE=!DRIVE:G=g!"
    set "DRIVE=!DRIVE:H=h!"
    set "DRIVE=!DRIVE:I=i!"
    set "DRIVE=!DRIVE:J=j!"
    set "DRIVE=!DRIVE:K=k!"
    set "DRIVE=!DRIVE:L=l!"
    set "DRIVE=!DRIVE:M=m!"
    set "DRIVE=!DRIVE:N=n!"
    set "DRIVE=!DRIVE:O=o!"
    set "DRIVE=!DRIVE:P=p!"
    set "DRIVE=!DRIVE:Q=q!"
    set "DRIVE=!DRIVE:R=r!"
    set "DRIVE=!DRIVE:S=s!"
    set "DRIVE=!DRIVE:T=t!"
    set "DRIVE=!DRIVE:U=u!"
    set "DRIVE=!DRIVE:V=v!"
    set "DRIVE=!DRIVE:W=w!"
    set "DRIVE=!DRIVE:X=x!"
    set "DRIVE=!DRIVE:Y=y!"
    set "DRIVE=!DRIVE:Z=z!"
    set "UNIX_PATH=/!DRIVE!!UNIX_PATH:~2!"
)

REM Run the bash installation script
echo Running installation script...
echo.
"!GITBASH!" -c "cd '!UNIX_PATH!' && bash ./install.sh"

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
