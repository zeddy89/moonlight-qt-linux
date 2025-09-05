#!/bin/bash
# Simple Docker build script for Moonlight-Qt

set -e

echo "==================================="
echo "  Moonlight-Qt Docker Build"
echo "==================================="
echo ""

VERSION="v5.0.1-z1-optimized"
OUTPUT_DIR="docker-output"

# Create output directory
mkdir -p $OUTPUT_DIR

# Create Dockerfile
cat > Dockerfile.build << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y \
    build-essential cmake git pkg-config \
    qt6-base-dev qt6-declarative-dev libqt6svg6-dev \
    qml6-module-qtquick-controls qml6-module-qtquick-templates \
    qml6-module-qtquick-layouts qml6-module-qtqml-workerscript \
    qml6-module-qtquick-window qml6-module-qtquick-dialogs \
    libavcodec-dev libavformat-dev libavutil-dev libswscale-dev \
    libsdl2-dev libsdl2-ttf-dev libopus-dev \
    libssl-dev libva-dev libvdpau-dev libpulse-dev \
    libdrm-dev libegl1-mesa-dev libgl1-mesa-dev \
    libx11-dev libxcb1-dev libxkbcommon-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
EOF

echo "[1/4] Building Docker image..."
docker build -t moonlight-build-env -f Dockerfile.build .

echo ""
echo "[2/4] Building Moonlight in Docker..."
docker run --rm \
    -v "$(pwd):/source:ro" \
    -v "$(pwd)/$OUTPUT_DIR:/output" \
    moonlight-build-env bash -c '
set -e
echo "Copying source..."
cp -r /source/* /build/

echo "Initializing submodules..."
cd /build
git submodule update --init --recursive

echo "Building h264bitstream..."
cd h264bitstream
make -j$(nproc)
cd ..

echo "Building moonlight-common-c..."
cd moonlight-common-c
mkdir -p build && cd build
cmake ..
make -j$(nproc)
cd ../..

echo "Building Moonlight-Qt..."
mkdir -p build && cd build
qmake6 ../moonlight-qt.pro \
    CONFIG+=release \
    QMAKE_CXXFLAGS+="-march=znver3 -O3 -flto" \
    QMAKE_CFLAGS+="-march=znver3 -O3 -flto" \
    QMAKE_LFLAGS+="-flto -Wl,-O1"
make -j$(nproc)

echo "Packaging..."
PACKAGE_NAME="moonlight-qt-'$VERSION'-linux-x86_64"
mkdir -p /output/$PACKAGE_NAME

find . -name moonlight -type f -executable -exec cp {} /output/$PACKAGE_NAME/moonlight \;
strip --strip-all /output/$PACKAGE_NAME/moonlight
chmod +x /output/$PACKAGE_NAME/moonlight

# Create launcher
cat > /output/$PACKAGE_NAME/launcher.sh << "SCRIPT"
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland
export AMD_VULKAN_ICD=RADV
exec "$DIR/moonlight" "$@"
SCRIPT
chmod +x /output/$PACKAGE_NAME/launcher.sh

# Create archive
cd /output
tar czf $PACKAGE_NAME.tar.gz $PACKAGE_NAME
echo "Build complete! Package created: $PACKAGE_NAME.tar.gz"
'

echo ""
echo "[3/4] Build complete!"
ls -lh $OUTPUT_DIR/*.tar.gz

echo ""
echo "[4/4] Ready to upload to GitHub"
echo "Run: gh release upload $VERSION $OUTPUT_DIR/*.tar.gz"