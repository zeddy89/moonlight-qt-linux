@echo off
REM Build script for Moonlight-Qt with optimizations on Windows
REM Prerequisites: 
REM - Qt 6.7+ SDK installed
REM - Visual Studio 2022 or later
REM - Run this from a Qt command prompt

echo ========================================
echo Moonlight-Qt Build Script for Windows
echo With Low-Latency and SteamOS Optimizations
echo ========================================
echo.

REM Check if qmake is available
where qmake6 >nul 2>&1
if %errorlevel% neq 0 (
    where qmake >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: qmake not found. Please run this from a Qt command prompt.
        echo Install Qt 6.7+ SDK and Visual Studio 2022.
        pause
        exit /b 1
    )
    set QMAKE=qmake
) else (
    set QMAKE=qmake6
)

echo Using %QMAKE%...
echo.

REM Clean previous build
if exist Makefile (
    echo Cleaning previous build...
    nmake clean >nul 2>&1
    del Makefile* >nul 2>&1
)

REM Run qmake
echo Running qmake...
%QMAKE% moonlight-qt.pro
if %errorlevel% neq 0 (
    echo ERROR: qmake failed!
    pause
    exit /b 1
)

REM Build the project
echo.
echo Building Moonlight-Qt...
echo This may take several minutes...
nmake
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed!
    echo Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo The executable should be in the 'release' or 'debug' folder.
echo.
echo New features added:
echo - Low-latency optimization mode (in Advanced Settings)
echo - SteamOS/Gamescope optimizations (in Advanced Settings)
echo.
pause