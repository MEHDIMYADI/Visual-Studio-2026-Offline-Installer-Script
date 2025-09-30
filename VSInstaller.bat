@echo off
setlocal enabledelayedexpansion

REM ==========================
REM Self-elevate as Administrator

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM ==========================
REM Check if curl is available
where curl >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: curl is not found. Please install curl or use Windows 10/11.
    pause
    exit /b
)

REM ==========================
REM Current script directory
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"
echo Script directory: %SCRIPT_DIR%

REM ==========================
REM Define default layout directory
set "LAYOUT_DIR=%SCRIPT_DIR%VSLayout"
if not exist "%LAYOUT_DIR%" mkdir "%LAYOUT_DIR%"
echo Default layout directory: %LAYOUT_DIR%

REM ==========================
REM Ask user which edition to install
:MAIN_MENU
echo.
echo Select Visual Studio edition:
echo 1 - Enterprise
echo 2 - Professional
echo 3 - Community
set /p EDITION_CHOICE=Enter number [1-3]:

if "%EDITION_CHOICE%"=="1" goto EDITION_1
if "%EDITION_CHOICE%"=="2" goto EDITION_2
if "%EDITION_CHOICE%"=="3" goto EDITION_3
goto MAIN_MENU

:EDITION_1
set "VS_EXE=vs_enterprise.exe"
set "VS_URL=https://aka.ms/vs/18/insiders/vs_Enterprise.exe"
goto NEXT_STEP

:EDITION_2
set "VS_EXE=vs_professional.exe"
set "VS_URL=https://aka.ms/vs/18/insiders/vs_Professional.exe"
goto NEXT_STEP

:EDITION_3
set "VS_EXE=vs_community.exe"
set "VS_URL=https://aka.ms/vs/18/insiders/vs_Community.exe"
goto NEXT_STEP

:NEXT_STEP
echo Selected edition: %VS_EXE%

REM ==========================
REM Second menu: Download/Update or Install Offline
:ACTION_MENU
echo.
echo What do you want to do next?
echo 1 - Download/Update bootstrapper and create offline layout
echo 2 - Install from existing offline layout
echo 3 - Check for old workloads from existing offline layout
set /p ACTION_CHOICE=Enter number [1-3]:

if "%ACTION_CHOICE%"=="1" goto ACTION_1
if "%ACTION_CHOICE%"=="2" goto ACTION_2
if "%ACTION_CHOICE%"=="3" goto ACTION_3

:ACTION_1
REM Download/update bootstrapper
if not exist "%VS_EXE%" (
	echo Downloading %VS_EXE%...
	curl -L -o "%VS_EXE%" "%VS_URL%" || (
		echo ERROR: Download failed.
		pause
		goto ACTION_MENU
	)
) else (
	echo Checking for bootstrapper updates...
	for %%A in ("%VS_EXE%") do set "LOCAL_SIZE=%%~zA"
	curl -s -D headers.txt -o nul "%VS_URL%"
	for /f "tokens=2 delims= " %%a in ('findstr /I "Content-Length" headers.txt') do set "ONLINE_SIZE=%%a"
	del headers.txt >nul 2>&1
	if not "%LOCAL_SIZE%"=="%ONLINE_SIZE%" (
		echo Newer bootstrapper detected. Downloading update...
		curl -L -o "%VS_EXE%" "%VS_URL%"
	) else (
		echo Local bootstrapper is up to date.
	)
)
REM Create/Update offline layout
echo Creating/Updating offline layout...
"%VS_EXE%" --layout "%LAYOUT_DIR%" --lang en-US --includeRecommended --includeOptional
echo Offline layout is ready in %LAYOUT_DIR%
pause
goto ACTION_MENU

:ACTION_2
REM Install from existing layout
if not exist "%LAYOUT_DIR%" (
	echo Layout folder not found! Please create offline layout first.
	pause
	goto ACTION_MENU
)
echo Launching installer from %LAYOUT_DIR%...
"%LAYOUT_DIR%\%VS_EXE%" --noweb --wait
pause
goto ACTION_MENU

:ACTION_3
REM ==========================
REM Check for old workloads - Skip folders without version silently

if not exist "%LAYOUT_DIR%" (
    echo Layout folder not found! Please create offline layout first.
    pause
    goto ACTION_MENU
)

echo Searching for old workloads...
set "OLD_FOUND=0"
set "OLDFILE=%SCRIPT_DIR%oldfiles.log"
del "%OLDFILE%" >nul 2>&1

REM ==========================
REM Process folders
for /d %%D in ("%LAYOUT_DIR%\*") do (
    set "FOLDER=%%~nxD"
    
    REM Only process folders that contain "version="
    echo !FOLDER! | findstr /I "version=" >nul
    if errorlevel 0 (
        REM Extract NAME and VERSION safely
        for /f "tokens=1,2 delims=," %%a in ("!FOLDER!") do (
            set "NAME=%%a"
            set "VERSTR=%%b"
        )
        set "VERSION=!VERSTR:version=!"

        REM Find latest version for this NAME
        set "LATEST=!VERSION!"
        for /d %%X in ("%LAYOUT_DIR%\!NAME!,version=*") do (
            set "OTHER=%%~nxX"
            for /f "tokens=1,2 delims=," %%m in ("!OTHER!") do (
                set "ONAME=%%m"
                set "OVERSTR=%%n"
            )
            set "OVER=!OVERSTR:version=!"
            
            REM Compare version numbers manually
            set "ISNEWER=0"
            for /f "tokens=1-4 delims=." %%i in ("!LATEST!") do (
                set "L1=%%i" & set "L2=%%j" & set "L3=%%k" & set "L4=%%l"
            )
            for /f "tokens=1-4 delims=." %%i in ("!OVER!") do (
                set "O1=%%i" & set "O2=%%j" & set "O3=%%k" & set "O4=%%l"
            )

            if !O1! GTR !L1! (set "ISNEWER=1") else if !O1! LSS !L1! (set "ISNEWER=-1")
            if !ISNEWER!==0 (
                if !O2! GTR !L2! (set "ISNEWER=1") else if !O2! LSS !L2! (set "ISNEWER=-1")
            )
            if !ISNEWER!==0 (
                if !O3! GTR !L3! (set "ISNEWER=1") else if !O3! LSS !L3! (set "ISNEWER=-1")
            )
            if !ISNEWER!==0 (
                if !O4! GTR !L4! (set "ISNEWER=1") else if !O4! LSS !L4! (set "ISNEWER=-1")
            )

            if !ISNEWER! GTR 0 set "LATEST=!OVER!"
        )

        REM If current version is older than latest → log it
        set "ISOLD=0"
        for /f "tokens=1-4 delims=." %%i in ("!VERSION!") do (
            set "C1=%%i" & set "C2=%%j" & set "C3=%%k" & set "C4=%%l"
        )
        for /f "tokens=1-4 delims=." %%i in ("!LATEST!") do (
            set "N1=%%i" & set "N2=%%j" & set "N3=%%k" & set "N4=%%l"
        )

        if !C1! LSS !N1! (set "ISOLD=1") else if !C1! EQU !N1! (
            if !C2! LSS !N2! (set "ISOLD=1") else if !C2! EQU !N2! (
                if !C3! LSS !N3! (set "ISOLD=1") else if !C3! EQU !N3! (
                    if !C4! LSS !N4! (set "ISOLD=1")
                )
            )
        )

        if !ISOLD! EQU 1 (
            echo Found old workload: !FOLDER!
            echo !FOLDER!>>"%OLDFILE%"
            set "OLD_FOUND=1"
        )
    )
)

REM ==========================
REM Handle result
if "%OLD_FOUND%"=="0" (
    echo No old workloads found.
) else (
    echo.
    echo Old workloads list saved in %OLDFILE%
    set /p CONFIRM=Do you want to delete ALL these old workloads? (Y/N):
    if /i "!CONFIRM!"=="Y" (
        for /f "usebackq delims=" %%L in ("%OLDFILE%") do (
            echo Deleting %%L ...
            rd /s /q "%LAYOUT_DIR%\%%L"
        )
        echo All old workloads deleted.
    ) else (
        echo Deletion skipped by user.
    )
)

pause
goto ACTION_MENU
