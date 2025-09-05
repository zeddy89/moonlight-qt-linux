#!/bin/bash
# Creates a portable AppImage for Moonlight-Qt Optimized
# This creates a single file you can run on any Linux system

set -e

echo "Creating Moonlight-Qt Optimized AppImage..."

# Build directory
BUILD_DIR="build-appimage"
APP_DIR="$BUILD_DIR/AppDir"

# Clean and create directories
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/lib"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"

# First build Moonlight
echo "Building Moonlight-Qt..."
mkdir -p "$BUILD_DIR/build"
cd "$BUILD_DIR/build"

# Configure with optimizations
if command -v qmake6 >/dev/null 2>&1; then
    QMAKE=qmake6
elif command -v qmake-qt6 >/dev/null 2>&1; then
    QMAKE=qmake-qt6
else
    QMAKE=qmake
fi

$QMAKE ../../moonlight-qt.pro \
    CONFIG+=release \
    PREFIX=/usr \
    QMAKE_CXXFLAGS+="-march=x86-64-v3 -O3" \
    QMAKE_CFLAGS+="-march=x86-64-v3 -O3"

# Build
make -j$(nproc)

# Find and copy executable
MOONLIGHT_BIN=$(find . -name "moonlight" -type f -executable | head -1)
cp "$MOONLIGHT_BIN" "../AppDir/usr/bin/moonlight"

cd ../..

# Create launcher script
cat > "$APP_DIR/usr/bin/moonlight-launcher.sh" <<'EOF'
#!/bin/bash
# AppImage launcher with optimizations

# Get the AppImage directory
HERE="$(dirname "$(readlink -f "${0}")")"

# Set library path
export LD_LIBRARY_PATH="${HERE}/../lib:${LD_LIBRARY_PATH}"

# Gamescope/Wayland optimizations
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland;xcb
export MOZ_ENABLE_WAYLAND=1

# GPU optimizations
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_SHADER_DISK_CACHE=1
export AMD_VULKAN_ICD=RADV
export RADV_PERFTEST=gpl,nggc,rtwave64

# Launch Moonlight
exec "${HERE}/moonlight" "$@"
EOF

chmod +x "$APP_DIR/usr/bin/moonlight-launcher.sh"
chmod +x "$APP_DIR/usr/bin/moonlight"

# Create desktop file
cat > "$APP_DIR/usr/share/applications/moonlight-optimized.desktop" <<EOF
[Desktop Entry]
Name=Moonlight (Optimized)
Comment=Stream games with Ryzen Z1 optimizations
Exec=moonlight-launcher.sh
Icon=moonlight
Terminal=false
Type=Application
Categories=Game;
StartupNotify=true
EOF

# Create AppRun script
cat > "$APP_DIR/AppRun" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/moonlight-launcher.sh" "$@"
EOF

chmod +x "$APP_DIR/AppRun"

# Create icon
cat > "$APP_DIR/moonlight.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
  <rect width="256" height="256" fill="#2196F3"/>
  <text x="128" y="180" font-family="Arial" font-size="180" fill="white" text-anchor="middle">M</text>
</svg>
EOF

convert "$APP_DIR/moonlight.svg" -resize 256x256 "$APP_DIR/usr/share/icons/hicolor/256x256/apps/moonlight.png" 2>/dev/null || \
cp "$APP_DIR/moonlight.svg" "$APP_DIR/usr/share/icons/hicolor/256x256/apps/moonlight.svg"

# Download appimagetool if not present
if [ ! -f appimagetool-x86_64.AppImage ]; then
    echo "Downloading appimagetool..."
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

# Create AppImage
echo "Creating AppImage..."
./appimagetool-x86_64.AppImage "$APP_DIR" "Moonlight-Qt-Optimized-x86_64.AppImage"

echo "======================================"
echo "AppImage created successfully!"
echo "File: Moonlight-Qt-Optimized-x86_64.AppImage"
echo ""
echo "To use:"
echo "1. Copy to your Steam Deck/Legion Go"
echo "2. Make executable: chmod +x Moonlight-Qt-Optimized-x86_64.AppImage"
echo "3. Run: ./Moonlight-Qt-Optimized-x86_64.AppImage"
echo "======================================"