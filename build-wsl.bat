@echo off
REM Build Moonlight-Qt for Linux using WSL
echo ========================================
echo Building Moonlight-Qt for Linux via WSL
echo ========================================
echo.

REM Check if WSL is installed
wsl --status >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: WSL is not installed or not available
    echo Please install WSL2 and a Linux distribution first
    echo.
    echo To install WSL:
    echo   wsl --install
    echo   wsl --install -d Ubuntu-22.04
    pause
    exit /b 1
)

echo Detected WSL installation
echo.

REM Convert Windows path to WSL path
set WSL_PATH=/mnt/f/Linux/moonlight-qt-linux

echo Starting Linux build in WSL...
echo.

REM Run build in WSL
wsl bash -c "cd %WSL_PATH% && chmod +x build-steamos.sh && ./build-steamos.sh"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Build completed successfully!
    echo ========================================
    echo.
    echo The Linux binary is in: build-steamos/
    echo.
    echo To copy to your Steam Deck/Legion Go:
    echo 1. Copy the entire build-steamos folder
    echo 2. Run moonlight-steamos.sh on the device
    echo.
) else (
    echo.
    echo Build failed. Please check the error messages above.
    echo.
)

pause