#!/bin/bash
# Quick Build Script for SL-3000 OpenWrt Firmware
# For local Ubuntu/Debian system

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}OpenWrt Quick Build for SL-3000 (MT7981)${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please do not run as root${NC}"
   exit 1
fi

# Configuration
WORK_DIR="$HOME/openwrt-sl3000-build"
REPO_URL="https://github.com/immortalwrt/immortalwrt"
REPO_BRANCH="openwrt-24.10"
JOBS=$(nproc)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=1
            shift
            ;;
        -d|--download)
            DOWNLOAD_ONLY=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -j, --jobs N       Use N parallel jobs (default: $(nproc))"
            echo "  -c, --clean        Clean build directory before compiling"
            echo "  -d, --download     Download only, don't compile"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Install dependencies
echo -e "${YELLOW}[1/7] Installing dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y \
    build-essential clang flex bison g++ gawk \
    gcc-multilib g++-multilib gettext git \
    libncurses5-dev libssl-dev python3-distutils \
    rsync unzip zlib1g-dev file wget curl \
    time jq ca-certificates python3

# Create working directory
echo -e "${YELLOW}[2/7] Setting up working directory...${NC}"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Clone or update source
echo -e "${YELLOW}[3/7] Cloning/updating source code...${NC}"
if [ -d "immortalwrt/.git" ]; then
    echo "Source exists, updating..."
    cd immortalwrt
    git fetch --depth 1 origin $REPO_BRANCH
    git reset --hard origin/$REPO_BRANCH
else
    echo "Cloning source..."
    git clone --depth 1 -b $REPO_BRANCH $REPO_URL immortalwrt
    cd immortalwrt
fi

# Clean if requested
if [ "$CLEAN" = "1" ]; then
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    make clean
    rm -rf bin build_dir/staging_dir
fi

# Copy configuration files
echo -e "${YELLOW}[4/7] Copying configuration...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.config" ]; then
    cp "$SCRIPT_DIR/.config" .config
    echo "Config copied from $SCRIPT_DIR/.config"
else
    echo -e "${RED}Warning: .config not found, using default${NC}"
fi

if [ -f "$SCRIPT_DIR/feeds.conf" ]; then
    cp "$SCRIPT_DIR/feeds.conf" feeds.conf
    echo "Feeds config copied"
fi

# Update feeds
echo -e "${YELLOW}[5/7] Updating feeds...${NC}"
./scripts/feeds update -a
./scripts/feeds install -a

# Apply configuration
echo -e "${YELLOW}[6/7] Applying configuration...${NC}"
make defconfig

# Download packages
echo -e "${YELLOW}[7/7] Downloading packages...${NC}"
make download -j$JOBS

# Check for failed downloads
find dl -size -1024c -exec rm -f {} \;

if [ "$DOWNLOAD_ONLY" = "1" ]; then
    echo -e "${GREEN}Download complete!${NC}"
    exit 0
fi

# Compile
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}Starting compilation with $JOBS jobs...${NC}"
echo -e "${GREEN}This will take 1-3 hours...${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

if make -j$JOBS V=s; then
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    
    OUTPUT_DIR="bin/targets/mediatek/filogic"
    if [ -d "$OUTPUT_DIR" ]; then
        echo -e "${GREEN}Firmware files:${NC}"
        ls -lh $OUTPUT_DIR/*.bin 2>/dev/null || true
        echo ""
        echo -e "${GREEN}Output directory: $PWD/$OUTPUT_DIR${NC}"
    fi
else
    echo ""
    echo -e "${RED}==========================================${NC}"
    echo -e "${RED}Build failed!${NC}"
    echo -e "${RED}==========================================${NC}"
    echo ""
    echo "Try running with single thread to see error details:"
    echo "  make -j1 V=s"
    exit 1
fi
