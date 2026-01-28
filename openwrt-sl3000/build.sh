#!/bin/bash
# OpenWrt Build Script for SL-3000 (MT7981)

set -e

echo "=========================================="
echo "OpenWrt Build Script for SL-3000 (MT7981)"
echo "=========================================="
echo ""

cd /home/builder/immortalwrt

# Check if .config exists
if [ ! -f ".config" ]; then
    echo "Error: .config file not found!"
    exit 1
fi

# Update feeds
echo "[1/5] Updating feeds..."
./scripts/feeds update -a

# Install feeds
echo "[2/5] Installing feeds..."
./scripts/feeds install -a

# Apply configuration
echo "[3/5] Applying configuration..."
make defconfig

# Download packages
echo "[4/5] Downloading packages..."
make download -j$(nproc) V=s 2>&1 | tee download.log || true

# Check for download failures
if grep -q "ERROR:" download.log 2>/dev/null; then
    echo "Warning: Some packages failed to download, will retry..."
    make download -j1 V=s
fi

# Start compilation
echo "[5/5] Starting compilation..."
echo "This may take 1-3 hours depending on your system..."
echo ""

make -j$(nproc) V=s 2>&1 | tee build.log

# Check if build succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Build completed successfully!"
    echo "=========================================="
    echo ""
    echo "Firmware files are located in:"
    echo "  bin/targets/mediatek/filogic/"
    echo ""
    echo "Look for files like:"
    echo "  - immortalwrt-mediatek-filogic-sl-3000-squashfs-sysupgrade.bin"
    echo "  - immortalwrt-mediatek-filogic-sl-3000-ext4-sysupgrade.bin"
    echo ""
    
    # List generated files
    ls -la bin/targets/mediatek/filogic/*.bin 2>/dev/null || echo "No .bin files found"
else
    echo ""
    echo "=========================================="
    echo "Build failed! Check build.log for errors"
    echo "=========================================="
    exit 1
fi
