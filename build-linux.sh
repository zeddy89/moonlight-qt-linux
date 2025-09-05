#!/bin/bash
# Build script for Moonlight-Qt on Linux/SteamOS
# Optimized for AMD Ryzen Z1/Z1 Extreme processors

echo "========================================"
echo "Moonlight-Qt Build Script for Linux/SteamOS"
echo "With Low-Latency and Gamescope Optimizations"
echo "========================================"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for Qt
if command_exists qmake; then
    QT_VERSION=$(qmake -query QT_VERSION)
    echo -e "${GREEN}Found Qt version: $QT_VERSION${NC}"
elif command_exists qmake-qt6; then
    echo -e "${GREEN}Found Qt6 (using qmake-qt6)${NC}"
    alias qmake='qmake-qt6'
elif command_exists qmake6; then
    echo -e "${GREEN}Found Qt6 (using qmake6)${NC}"
    alias qmake='qmake6'
else
    echo -e "${RED}Error: Qt not found. Please install Qt6 development packages.${NC}"
    echo "For SteamOS/Arch Linux: sudo pacman -S qt6-base qt6-declarative qt6-svg qt6-quickcontrols2"
    echo "For Ubuntu/Debian: sudo apt install qt6-base-dev qt6-declarative-dev libqt6svg6-dev qml6-module-qtquick-controls2"
    exit 1
fi

# Check for other dependencies
MISSING_DEPS=""

if ! command_exists g++; then
    MISSING_DEPS="$MISSING_DEPS g++"
fi

if ! command_exists pkg-config; then
    MISSING_DEPS="$MISSING_DEPS pkg-config"
fi

if ! pkg-config --exists libavcodec; then
    MISSING_DEPS="$MISSING_DEPS ffmpeg"
fi

if ! pkg-config --exists sdl2; then
    MISSING_DEPS="$MISSING_DEPS sdl2"
fi

if ! pkg-config --exists SDL2_ttf; then
    MISSING_DEPS="$MISSING_DEPS sdl2_ttf"
fi

if ! pkg-config --exists opus; then
    MISSING_DEPS="$MISSING_DEPS opus"
fi

if [ ! -z "$MISSING_DEPS" ]; then
    echo -e "${RED}Error: Missing dependencies: $MISSING_DEPS${NC}"
    echo
    echo "For SteamOS/Arch Linux, run:"
    echo "sudo pacman -S base-devel ffmpeg sdl2 sdl2_ttf opus"
    echo
    echo "For Ubuntu/Debian, run:"
    echo "sudo apt install build-essential libavcodec-dev libavformat-dev libavutil-dev libsdl2-dev libsdl2-ttf-dev libopus-dev"
    exit 1
fi

echo -e "${GREEN}All dependencies found!${NC}"
echo

# Update submodules
echo -e "${YELLOW}Updating git submodules...${NC}"
git submodule update --init --recursive || {
    echo -e "${YELLOW}Warning: Failed to update submodules, continuing anyway...${NC}"
}

# Clean previous build
if [ -f Makefile ]; then
    echo -e "${YELLOW}Cleaning previous build...${NC}"
    make clean 2>/dev/null || true
    rm -f Makefile* 2>/dev/null || true
fi

# Create build directory
BUILD_DIR="build-linux"
if [ ! -d "$BUILD_DIR" ]; then
    mkdir -p "$BUILD_DIR"
fi

cd "$BUILD_DIR"

# Configure with qmake
echo -e "${YELLOW}Configuring build with qmake...${NC}"
qmake ../moonlight-qt.pro \
    CONFIG+=release \
    CONFIG+=optimize_size \
    CONFIG+=ltcg \
    QMAKE_CXXFLAGS+="-march=native -mtune=native -O3" \
    QMAKE_CFLAGS+="-march=native -mtune=native -O3" || {
    echo -e "${RED}Error: qmake configuration failed!${NC}"
    exit 1
}

# Get number of CPU cores for parallel compilation
NPROC=$(nproc 2>/dev/null || echo 4)

echo
echo -e "${YELLOW}Building Moonlight-Qt with $NPROC parallel jobs...${NC}"
echo "This may take 10-20 minutes..."
echo

# Build
make -j$NPROC || {
    echo
    echo -e "${RED}Error: Build failed!${NC}"
    echo "Trying single-threaded build..."
    make || {
        echo
        echo -e "${RED}Build still failed. Please check the error messages above.${NC}"
        exit 1
    }
}

echo
echo -e "${GREEN}========================================"
echo "Build completed successfully!"
echo "========================================${NC}"
echo

# Find the executable
if [ -f "app/moonlight" ]; then
    EXECUTABLE="app/moonlight"
elif [ -f "moonlight" ]; then
    EXECUTABLE="moonlight"
else
    echo -e "${YELLOW}Warning: Could not find moonlight executable in expected locations${NC}"
    EXECUTABLE=""
fi

if [ ! -z "$EXECUTABLE" ]; then
    echo -e "${GREEN}Executable location: $(pwd)/$EXECUTABLE${NC}"
    
    # Make it executable
    chmod +x "$EXECUTABLE"
    
    # Create desktop entry for SteamOS/Linux desktop
    echo
    echo -e "${YELLOW}Creating desktop entry...${NC}"
    
    DESKTOP_FILE="$HOME/.local/share/applications/moonlight-qt-optimized.desktop"
    mkdir -p "$HOME/.local/share/applications"
    
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Moonlight (Optimized)
Comment=Stream games from your PC with low-latency optimizations
Exec=$(pwd)/$EXECUTABLE
Icon=moonlight
Terminal=false
Type=Application
Categories=Game;
Keywords=stream;games;nvidia;gamestream;
EOF
    
    echo -e "${GREEN}Desktop entry created at: $DESKTOP_FILE${NC}"
fi

echo
echo -e "${GREEN}New optimization features available:${NC}"
echo "• Low-latency mode for Ryzen Z1/Z1 Extreme (in Advanced Settings)"
echo "• SteamOS/Gamescope optimizations (in Advanced Settings)"
echo
echo -e "${YELLOW}To run Moonlight:${NC}"
if [ ! -z "$EXECUTABLE" ]; then
    echo "  cd $(pwd)"
    echo "  ./$EXECUTABLE"
else
    echo "  Find and run the moonlight executable in the build directory"
fi
echo
echo -e "${YELLOW}For Steam Deck Game Mode:${NC}"
echo "  Add as non-Steam game and launch from Game Mode"
echo
echo -e "${GREEN}Optimizations are specifically tuned for:${NC}"
echo "• Legion Go with Ryzen Z1 Extreme"
echo "• Steam Deck"
echo "• ROG Ally"
echo "• Other AMD-based handhelds"
echo

# Create systemd service for auto-start (optional)
echo -e "${YELLOW}Do you want to create a systemd service for auto-start? (y/N)${NC}"
read -r CREATE_SERVICE

if [[ "$CREATE_SERVICE" =~ ^[Yy]$ ]]; then
    SERVICE_FILE="$HOME/.config/systemd/user/moonlight-qt.service"
    mkdir -p "$HOME/.config/systemd/user"
    
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Moonlight Qt Game Streaming Client
After=graphical-session.target

[Service]
Type=simple
ExecStart=$(pwd)/$EXECUTABLE
Restart=on-failure
RestartSec=5
Environment="QT_QPA_PLATFORM=xcb"
Environment="SDL_VIDEODRIVER=x11"

[Install]
WantedBy=default.target
EOF
    
    echo -e "${GREEN}Systemd service created at: $SERVICE_FILE${NC}"
    echo "To enable auto-start, run:"
    echo "  systemctl --user enable moonlight-qt.service"
    echo "  systemctl --user start moonlight-qt.service"
fi

echo
echo -e "${GREEN}Build complete! Enjoy low-latency game streaming!${NC}"