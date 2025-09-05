@echo off
REM Build script for Moonlight-Qt with MinGW on Windows
REM Using Qt 6.9.2 with MinGW compiler

echo ========================================
echo Moonlight-Qt Build Script for Windows (MinGW)
echo With Low-Latency and SteamOS Optimizations
echo ========================================
echo.

set QTDIR=C:\Qt\6.9.2\mingw_64
set MINGW=C:\Qt\Tools\mingw1310_64
set PATH=%QTDIR%\bin;%MINGW%\bin;%PATH%

REM Check if qmake is available
where qmake >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: qmake not found. Checking Qt installation...
    if not exist "%QTDIR%\bin\qmake.exe" (
        echo ERROR: Qt not found at %QTDIR%
        pause
        exit /b 1
    )
)

echo Using Qt from: %QTDIR%
echo.

REM Update submodules first
echo Updating git submodules...
git submodule update --init --recursive
if %errorlevel% neq 0 (
    echo WARNING: Failed to update submodules, continuing anyway...
)

REM Clean previous build
if exist Makefile (
    echo Cleaning previous build...
    mingw32-make clean >nul 2>&1
    del Makefile* >nul 2>&1
)

REM Run qmake
echo Running qmake...
"%QTDIR%\bin\qmake.exe" moonlight-qt.pro
if %errorlevel% neq 0 (
    echo ERROR: qmake failed!
    pause
    exit /b 1
)

echo.
echo Building Moonlight-Qt with MinGW...
echo This may take 10-20 minutes...
echo.

REM Build with multiple cores for faster compilation
mingw32-make -j%NUMBER_OF_PROCESSORS%
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed!
    echo Trying single-threaded build...
    mingw32-make
    if %errorlevel% neq 0 (
        echo.
        echo Build still failed. Please check the error messages above.
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo The executable should be in the 'release' folder.
echo.
echo New features added:
echo - Low-latency optimization mode (in Advanced Settings)
echo - SteamOS/Gamescope optimizations (in Advanced Settings)
echo.

REM Copy required Qt DLLs
echo Deploying Qt dependencies...
"%QTDIR%\bin\windeployqt.exe" release\moonlight.exe --qmldir app\gui
if %errorlevel% neq 0 (
    echo WARNING: Failed to deploy Qt dependencies
)

echo.
echo Build complete! You can find the executable at:
echo release\moonlight.exe
echo.
pause