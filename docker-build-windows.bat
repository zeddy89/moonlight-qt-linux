@echo off
echo =========================================
echo    Moonlight-Qt Docker Build (Windows)
echo =========================================
echo.

set VERSION=v5.0.1-z1-optimized
set OUTPUT_DIR=docker-output

:: Clean output directory
if exist %OUTPUT_DIR% rmdir /s /q %OUTPUT_DIR%
mkdir %OUTPUT_DIR%

echo [1/3] Pulling Ubuntu 22.04 image...
docker pull ubuntu:22.04

echo.
echo [2/3] Building Moonlight in Docker...
echo This will take 10-15 minutes...
echo.

:: Run Docker build with Windows-compatible paths
docker run --rm -v "%CD%:/source" -v "%CD%/%OUTPUT_DIR%:/output" -w /source ubuntu:22.04 bash -c "echo '=== Installing dependencies ===' && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake git qt6-base-dev qt6-declarative-dev libqt6svg6-dev qml6-module-qtquick-controls libavcodec-dev libavformat-dev libsdl2-dev libsdl2-ttf-dev libopus-dev libssl-dev libva-dev libvdpau-dev libpulse-dev && echo '=== Configuring git ===' && git config --global --add safe.directory /source && echo '=== Updating submodules ===' && git submodule update --init --recursive && echo '=== Building h264bitstream ===' && cd /source/h264bitstream && make clean 2>/dev/null || true && make -j$(nproc) && echo '=== Building moonlight-common-c ===' && cd /source/moonlight-common-c && rm -rf build && mkdir build && cd build && cmake .. && make -j$(nproc) && echo '=== Building Moonlight-Qt ===' && cd /source && rm -rf build && mkdir build && cd build && qmake6 ../moonlight-qt.pro CONFIG+=release && make -j$(nproc) || make && echo '=== Packaging ===' && mkdir -p /output/moonlight-qt-%VERSION%-linux-x86_64 && find . -name moonlight -type f -executable -exec cp {} /output/moonlight-qt-%VERSION%-linux-x86_64/moonlight \; && chmod +x /output/moonlight-qt-%VERSION%-linux-x86_64/moonlight && cd /output && tar czf moonlight-qt-%VERSION%-linux-x86_64.tar.gz moonlight-qt-%VERSION%-linux-x86_64 && echo 'Build complete!' && ls -lh *.tar.gz"

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    exit /b 1
)

echo.
echo [3/3] Build complete!
echo.
echo Checking output...
dir %OUTPUT_DIR%\*.tar.gz 2>nul
if errorlevel 1 (
    echo No package found - build may have failed
) else (
    echo.
    echo SUCCESS! Binary package created.
    echo Location: %OUTPUT_DIR%\
)

echo.
echo To upload to GitHub:
echo   gh release upload %VERSION% %OUTPUT_DIR%\*.tar.gz