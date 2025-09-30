@echo off
setlocal enabledelayedexpansion

REM ==========================
REM Log all output
set "LOGFILE=%~dp0VSInstaller.log"
echo ===== Visual Studio Installer Log ===== > "%LOGFILE%"
echo Started at %date% %time% >> "%LOGFILE%"
echo. >> "%LOGFILE%"

call :Log "Initializing script..."

REM ==========================
REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    call :Log "ERROR: Please run this script as Administrator!"
    pause
    exit /b
)

REM ==========================
REM Check if curl is available
where curl >nul 2>&1
if %errorLevel% NEQ 0 (
    call :Log "ERROR: curl is not found. Please install curl or use Windows 10/11."
    pause
    exit /b
)

REM ==========================
REM Current script directory
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"
call :Log "Script directory: %SCRIPT_DIR%"

REM ==========================
REM Define layout directory
set "LAYOUT_DIR=%SCRIPT_DIR%VSLayout"
if not exist "%LAYOUT_DIR%" mkdir "%LAYOUT_DIR%"
call :Log "Layout directory: %LAYOUT_DIR%"

REM ==========================
REM Ask user which edition to install
echo Select Visual Studio edition:
echo 1 - Enterprise
echo 2 - Professional
echo 3 - Community
set /p EDITION_CHOICE=Enter number [1-3]:
set "EDITION_CHOICE=%EDITION_CHOICE: =%"

if "%EDITION_CHOICE%"=="1" (
    set "VS_EXE=vs_enterprise.exe"
    set "VS_URL=https://aka.ms/vs/18/insiders/vs_Enterprise.exe"
) else if "%EDITION_CHOICE%"=="2" (
    set "VS_EXE=vs_professional.exe"
    set "VS_URL=https://aka.ms/vs/18/insiders/vs_Professional.exe"
) else if "%EDITION_CHOICE%"=="3" (
    set "VS_EXE=vs_community.exe"
    set "VS_URL=https://aka.ms/vs/18/insiders/vs_Community.exe"
) else (
    call :Log "Invalid choice. Exiting."
    pause
    exit /b
)

call :Log "Selected edition: %VS_EXE%"

REM ==========================
REM Check bootstrapper version / download if missing
call :Log "[1] Checking bootstrapper version..."
if not exist "%VS_EXE%" (
    call :Log "Bootstrapper not found. Downloading latest..."
    curl -L -o "%VS_EXE%" "%VS_URL%" || (
        call :Log "ERROR: Download failed."
        pause
        exit /b
    )
) else (
    for %%A in ("%VS_EXE%") do set "LOCAL_SIZE=%%~zA"
    curl -s -D headers.txt -o nul "%VS_URL%"
    for /f "tokens=2 delims= " %%a in ('findstr /I "Content-Length" headers.txt') do set "ONLINE_SIZE=%%a"
    del headers.txt >nul 2>&1

    if not "%LOCAL_SIZE%"=="%ONLINE_SIZE%" (
        call :Log "Newer bootstrapper detected. Downloading update..."
        curl -L -o "%VS_EXE%" "%VS_URL%"
    ) else (
        call :Log "Local bootstrapper is up to date."
    )
)

REM ==========================
call :Log "[3] Creating/Updating offline layout..."
"%VS_EXE%" --layout "%LAYOUT_DIR%" --lang en-US --includeRecommended --includeOptional

REM ==========================
call :Log "[4] Launching Visual Studio Installer (GUI) from offline layout..."
"%LAYOUT_DIR%\%VS_EXE%" --noweb --wait

REM ==========================
call :Log "All operations completed successfully."
pause
exit /b

REM ==========================
:Log
echo %~1
echo %~1 >> "%LOGFILE%"
goto :eof
