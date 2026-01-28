#!/bin/bash
# Manual Build Script for SL-3000 OpenWrt Firmware
# Run this inside the Docker container or on a Ubuntu system

set -e

WORK_DIR="/home/builder/immortalwrt"
FEEDS_CUSTOM="/home/builder/feeds.conf"
CONFIG_CUSTOM="/home/builder/.config"

echo "=========================================="
echo "OpenWrt Build Script for SL-3000 (MT7981)"
echo "=========================================="
echo ""

# Create working directory
mkdir -p $WORK_DIR
cd $WORK_DIR

# Step 1: Clone source code
echo "[1/8] Cloning ImmortalWrt source code..."
if [ ! -d "$WORK_DIR/.git" ]; then
    git clone --depth 1 -b openwrt-24.10 https://github.com/immortalwrt/immortalwrt.git $WORK_DIR
fi

# Step 2: Copy custom configuration
echo "[2/8] Copying custom configuration..."
if [ -f "$CONFIG_CUSTOM" ]; then
    cp $CONFIG_CUSTOM $WORK_DIR/.config
    echo "Custom .config applied"
fi

# Step 3: Copy custom feeds
echo "[3/8] Copying custom feeds configuration..."
if [ -f "$FEEDS_CUSTOM" ]; then
    cp $FEEDS_CUSTOM $WORK_DIR/feeds.conf
    echo "Custom feeds.conf applied"
fi

# Step 4: Update feeds
echo "[4/8] Updating feeds..."
cd $WORK_DIR
./scripts/feeds update -a 2>&1 | tee feeds-update.log

# Step 5: Install feeds
echo "[5/8] Installing feeds..."
./scripts/feeds install -a 2>&1 | tee feeds-install.log

# Step 6: Apply configuration
echo "[6/8] Applying configuration..."
make defconfig 2>&1 | tee defconfig.log

# Step 7: Download packages
echo "[7/8] Downloading packages..."
make download -j$(nproc) V=s 2>&1 | tee download.log || true

# Check for download failures and retry
if grep -q "ERROR:" download.log 2>/dev/null; then
    echo "Some packages failed to download, retrying with single thread..."
    make download -j1 V=s
fi

# Step 8: Compile
echo "[8/8] Starting compilation..."
echo "This will take 1-3 hours depending on your system..."
echo ""

# Clean previous build artifacts
rm -f $WORK_DIR/build.log

# Start compilation
make -j$(nproc) V=s 2>&1 | tee build.log

BUILD_STATUS=${PIPESTATUS[0]}

# Check result
if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Build completed successfully!"
    echo "=========================================="
    echo ""
    
    OUTPUT_DIR="$WORK_DIR/bin/targets/mediatek/filogic"
    
    if [ -d "$OUTPUT_DIR" ]; then
        echo "Generated firmware files:"
        ls -lh $OUTPUT_DIR/*.bin 2>/dev/null || echo "No .bin files found"
        echo ""
        echo "Factory files:"
        ls -lh $OUTPUT_DIR/*factory* 2>/dev/null || echo "No factory files"
        echo ""
        echo "Sysupgrade files:"
        ls -lh $OUTPUT_DIR/*sysupgrade* 2>/dev/null || echo "No sysupgrade files"
        echo ""
        echo "All files are in: $OUTPUT_DIR"
    fi
else
    echo ""
    echo "=========================================="
    echo "Build failed with exit code: $BUILD_STATUS"
    echo "=========================================="
    echo ""
    echo "Checking for common errors..."
    
    # Check for common errors
    if grep -q "No space left on device" build.log; then
        echo "Error: Disk space exhausted. Free up space and retry."
    elif grep -q "Cannot allocate memory" build.log; then
        echo "Error: Out of memory. Add swap space or reduce parallel jobs."
    elif grep -q "package.*failed to build" build.log; then
        echo "Error: Some packages failed to build. Check build.log for details."
    fi
    
    echo ""
    echo "To retry with single thread (slower but more stable):"
    echo "  make -j1 V=s"
    
    exit 1
fi
