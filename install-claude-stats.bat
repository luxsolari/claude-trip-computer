@echo off
REM Claude Code Session Stats Tracking - Windows Installer Wrapper
REM Version: 0.9.1
REM Automatically detects and installs prerequisites (jq, bc) if needed

setlocal enabledelayedexpansion

echo ================================================================
echo    Claude Code Session Stats Tracking - Windows Installer
echo    Version: 0.9.1
echo ================================================================
echo.

REM Check if running with admin privileges (needed for choco install)
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Not running as Administrator
    echo Some prerequisite installations may require elevation
    echo.
)

REM Try to find Git Bash
set GIT_BASH=
if exist "C:\Program Files\Git\bin\bash.exe" (
    set GIT_BASH=C:\Program Files\Git\bin\bash.exe
) else if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    set GIT_BASH=C:\Program Files (x86)\Git\bin\bash.exe
) else if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" (
    set GIT_BASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe
) else if exist "%PROGRAMFILES%\Git\bin\bash.exe" (
    set GIT_BASH=%PROGRAMFILES%\Git\bin\bash.exe
)

if "%GIT_BASH%"=="" (
    echo [ERROR] Git Bash not found
    echo.
    echo Git for Windows is required to run this installer.
    echo.
    echo Please install Git for Windows from:
    echo   https://git-scm.com/download/win
    echo.
    echo After installation, run this script again.
    echo.
    pause
    exit /b 1
)

echo [OK] Git Bash found: %GIT_BASH%
echo.

REM Check for prerequisites: jq and bc
echo Checking prerequisites...
echo.

set MISSING_PREREQS=0

REM Check for jq
"%GIT_BASH%" -c "command -v jq" >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] jq is not installed
    set MISSING_PREREQS=1
) else (
    echo [OK] jq is installed
)

REM Check for bc
"%GIT_BASH%" -c "command -v bc" >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] bc is not installed
    set MISSING_PREREQS=1
) else (
    echo [OK] bc is installed
)

echo.

REM If prerequisites are missing, offer to install them
if %MISSING_PREREQS% equ 1 (
    echo Some prerequisites are missing.
    echo.
    echo Would you like to install them automatically? ^(Y/N^)
    echo.
    echo Installation method:
    
    REM Check if Chocolatey is available
    where choco >nul 2>&1
    if %errorLevel% equ 0 (
        echo   - Using Chocolatey package manager
        echo   - This will install jq and bc if missing
        echo.
        set /p INSTALL_CHOICE="Install prerequisites? (Y/N): "
        
        if /i "!INSTALL_CHOICE!"=="Y" (
            echo.
            echo Installing prerequisites via Chocolatey...
            echo.
            
            REM Install jq if missing
            "%GIT_BASH%" -c "command -v jq" >nul 2>&1
            if !errorLevel! neq 0 (
                echo Installing jq...
                choco install jq -y
                if !errorLevel! neq 0 (
                    echo [ERROR] Failed to install jq
                    echo Please install manually: choco install jq
                    pause
                    exit /b 1
                )
                echo [OK] jq installed successfully
            )
            
            REM Install bc if missing (usually comes with Git Bash)
            "%GIT_BASH%" -c "command -v bc" >nul 2>&1
            if !errorLevel! neq 0 (
                echo [INFO] bc not found in Git Bash
                echo bc is typically included with Git Bash.
                echo.
                echo For manual installation, see:
                echo   https://stackoverflow.com/a/57787863/32131291
                echo.
                echo If the installer fails, please either:
                echo   - Reinstall Git for Windows, or
                echo   - Follow the manual bc installation guide above
            )
            
            echo.
            echo Prerequisites installed successfully
            echo.
        ) else (
            echo.
            echo Installation cancelled. Please install prerequisites manually:
            echo   - jq: choco install jq
            echo   - bc: See https://stackoverflow.com/a/57787863/32131291
            echo.
            pause
            exit /b 1
        )
    ) else (
        REM Chocolatey not available, provide manual instructions
        echo   - Chocolatey not found
        echo   - Manual installation required
        echo.
        echo Please install Chocolatey first, then run this script again:
        echo   https://chocolatey.org/install
        echo.
        echo Or manually install prerequisites:
        echo   - jq: Download from https://stedolan.github.io/jq/
        echo   - bc: See https://stackoverflow.com/a/57787863/32131291
        echo.
        pause
        exit /b 1
    )
)

REM Run the bash installer script
echo.
echo ================================================================
echo    Running installer...
echo ================================================================
echo.

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Run the shell script with Git Bash
"%GIT_BASH%" "%SCRIPT_DIR%install-claude-stats.sh"

REM Check exit code
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Installation failed with exit code %errorLevel%
    echo.
    pause
    exit /b %errorLevel%
)

echo.
echo ================================================================
echo    Installation complete!
echo ================================================================
echo.
echo You can now restart Claude Code to see the status line.
echo Run /trip-computer command for detailed analytics.
echo.
pause

