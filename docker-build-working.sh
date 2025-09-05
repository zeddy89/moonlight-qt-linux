#!/bin/bash
# Working Docker build script for Moonlight-Qt

set -e

echo "========================================="
echo "   Moonlight-Qt Docker Build"
echo "========================================="

VERSION="v5.0.1-z1-optimized"
OUTPUT_DIR="docker-output"

# Clean and create output directory
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

echo "[1/3] Pulling Ubuntu 22.04 base image..."
docker pull ubuntu:22.04

echo "[2/3] Building Moonlight in Docker..."
docker run --rm \
    -v "$(pwd):/source" \
    -v "$(pwd)/$OUTPUT_DIR:/output" \
    -w /source \
    ubuntu:22.04 bash -c '
echo "=== Installing dependencies ==="
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential cmake git \
    qt6-base-dev qt6-declarative-dev libqt6svg6-dev \
    qml6-module-qtquick-controls \
    libavcodec-dev libavformat-dev \
    libsdl2-dev libsdl2-ttf-dev libopus-dev \
    libssl-dev libva-dev libvdpau-dev libpulse-dev

echo "=== Initializing git submodules ==="
git config --global --add safe.directory /source
git submodule update --init --recursive

echo "=== Building h264bitstream ==="
cd /source/h264bitstream
make clean || true
make -j$(nproc)

echo "=== Building moonlight-common-c ==="
cd /source/moonlight-common-c
rm -rf build
mkdir build && cd build
cmake ..
make -j$(nproc)

echo "=== Building Moonlight-Qt ==="
cd /source
rm -rf build
mkdir build && cd build
qmake6 ../moonlight-qt.pro CONFIG+=release
make -j$(nproc) || make

echo "=== Packaging binary ==="
PACKAGE_NAME="moonlight-qt-'$VERSION'-linux-x86_64"
mkdir -p /output/$PACKAGE_NAME

# Find and copy binary
find . -name moonlight -type f -executable -exec cp {} /output/$PACKAGE_NAME/moonlight \; || \
    cp app/moonlight /output/$PACKAGE_NAME/moonlight || \
    cp moonlight /output/$PACKAGE_NAME/moonlight

# Make sure binary exists
if [ ! -f /output/$PACKAGE_NAME/moonlight ]; then
    echo "ERROR: moonlight binary not found!"
    exit 1
fi

chmod +x /output/$PACKAGE_NAME/moonlight

# Create launcher script
cat > /output/$PACKAGE_NAME/launch.sh << "SCRIPT"
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland
exec "$DIR/moonlight" "$@"
SCRIPT
chmod +x /output/$PACKAGE_NAME/launch.sh

# Create README
cat > /output/$PACKAGE_NAME/README.txt << "README"
Moonlight-Qt for SteamOS/Legion Go
Run: ./launch.sh
README

# Create archive
cd /output
tar czf $PACKAGE_NAME.tar.gz $PACKAGE_NAME
echo "SUCCESS: Package created at /output/$PACKAGE_NAME.tar.gz"
ls -lh *.tar.gz
'

echo "[3/3] Build complete!"
echo "Package location: $OUTPUT_DIR/"
ls -lh $OUTPUT_DIR/*.tar.gz 2>/dev/null || echo "No package found - check for errors above"