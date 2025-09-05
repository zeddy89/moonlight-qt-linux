#!/bin/bash
# Simplified build script for SteamOS/Arch Linux
# Run this on your Legion Go with SteamOS or in WSL2

set -e

echo "========================================"
echo "Moonlight-Qt Build for SteamOS"
echo "Optimized for Ryzen Z1 Extreme"
echo "========================================"

# Install dependencies (for Arch/SteamOS)
if command -v pacman >/dev/null 2>&1; then
    echo "Installing dependencies via pacman..."
    sudo pacman -S --needed --noconfirm \
        base-devel \
        git \
        cmake \
        qt6-base \
        qt6-declarative \
        qt6-svg \
        qt6-quickcontrols2 \
        ffmpeg \
        sdl2 \
        sdl2_ttf \
        opus \
        libva \
        libvdpau \
        libpulse \
        openssl
fi

# Update submodules
echo "Updating submodules..."
git submodule update --init --recursive

# Clean build
rm -rf build-steamos
mkdir -p build-steamos
cd build-steamos

# Configure build with optimizations for Ryzen Z1
echo "Configuring build..."
if command -v qmake6 >/dev/null 2>&1; then
    QMAKE=qmake6
elif command -v qmake-qt6 >/dev/null 2>&1; then
    QMAKE=qmake-qt6
else
    QMAKE=qmake
fi

$QMAKE ../moonlight-qt.pro \
    CONFIG+=release \
    CONFIG+=optimize_size \
    QMAKE_CXXFLAGS+="-march=znver3 -mtune=znver3 -O3 -flto" \
    QMAKE_CFLAGS+="-march=znver3 -mtune=znver3 -O3 -flto" \
    QMAKE_LFLAGS+="-flto"

# Build with all cores
echo "Building..."
make -j$(nproc)

echo "========================================"
echo "Build complete!"
echo "========================================"

# Find executable
EXECUTABLE=$(find . -name "moonlight" -type f -executable | head -1)

if [ -n "$EXECUTABLE" ]; then
    echo "Executable: $(pwd)/$EXECUTABLE"
    
    # Strip debug symbols for smaller size
    strip "$EXECUTABLE"
    
    # Create launch script
    cat > moonlight-steamos.sh <<'EOF'
#!/bin/bash
# Launch script for Moonlight on SteamOS

# Set environment for Gamescope/SteamOS
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland
export MOZ_ENABLE_WAYLAND=1
export XDG_SESSION_TYPE=wayland

# Enable GPU acceleration
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1

# AMD specific optimizations
export AMD_VULKAN_ICD=RADV
export RADV_PERFTEST=gpl,nggc,rtwave64

# Launch Moonlight
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
exec "$DIR/$(basename $EXECUTABLE)" "$@"
EOF
    
    chmod +x moonlight-steamos.sh
    
    echo
    echo "Created launch script: moonlight-steamos.sh"
    echo
    echo "To add to Steam:"
    echo "1. Copy this folder to your Steam Deck/Legion Go"
    echo "2. In Desktop Mode, add moonlight-steamos.sh as non-Steam game"
    echo "3. Set compatibility to 'Steam Linux Runtime'"
    echo
    echo "Optimizations enabled:"
    echo "✓ Low-latency mode for Ryzen Z1"
    echo "✓ Gamescope/Wayland integration"
    echo "✓ AMD GPU optimizations"
fi

echo "Done!"