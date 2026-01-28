#!/bin/bash
# Flash Helper Script for SL-3000
# This script helps with flashing OpenWrt firmware to SL-3000

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}SL-3000 Flash Helper${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# Functions
show_help() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  backup        Backup current firmware and configuration"
    echo "  flash-fip     Flash FIP to enable SPI-NOR access"
    echo "  flash-fw      Flash OpenWrt firmware"
    echo "  setup-docker  Setup Docker data directory on eMMC"
    echo "  install-ipk   Install .ipk packages from directory"
    echo ""
    echo "Options:"
    echo "  -h, --host    Router IP address (default: 192.168.1.1)"
    echo "  -f, --file    Firmware file path"
    echo "  --fip-file    FIP file path"
    echo ""
}

# Default values
ROUTER_IP="192.168.1.1"
FIRMWARE_FILE=""
FIP_FILE=""

# Parse arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        backup|flash-fip|flash-fw|setup-docker|install-ipk)
            COMMAND="$1"
            shift
            ;;
        -h|--host)
            ROUTER_IP="$2"
            shift 2
            ;;
        -f|--file)
            FIRMWARE_FILE="$2"
            shift 2
            ;;
        --fip-file)
            FIP_FILE="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$COMMAND" ]; then
    show_help
    exit 1
fi

# Execute command
case $COMMAND in
    backup)
        echo -e "${YELLOW}Backing up current configuration...${NC}"
        echo "Please ensure you can SSH into the router at $ROUTER_IP"
        echo ""
        
        BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        echo "Downloading backup..."
        ssh "root@$ROUTER_IP" "sysupgrade -b /tmp/backup.tar.gz" 2>/dev/null || true
        scp "root@$ROUTER_IP:/tmp/backup.tar.gz" "$BACKUP_DIR/" 2>/dev/null || {
            echo -e "${RED}Failed to download backup. Make sure SSH is enabled.${NC}"
            exit 1
        }
        
        echo -e "${GREEN}Backup saved to: $BACKUP_DIR/backup.tar.gz${NC}"
        ;;
        
    flash-fip)
        echo -e "${YELLOW}Flashing FIP to enable SPI-NOR access...${NC}"
        
        if [ -z "$FIP_FILE" ]; then
            echo -e "${RED}Error: Please specify FIP file with --fip-file${NC}"
            exit 1
        fi
        
        if [ ! -f "$FIP_FILE" ]; then
            echo -e "${RED}Error: FIP file not found: $FIP_FILE${NC}"
            exit 1
        fi
        
        echo "Uploading FIP file..."
        scp "$FIP_FILE" "root@$ROUTER_IP:/tmp/spinor_fip_by.bin"
        
        echo "Flashing FIP..."
        ssh "root@$ROUTER_IP" "mtd write /tmp/spinor_fip_by.bin FIP"
        
        echo -e "${GREEN}FIP flashed successfully!${NC}"
        echo -e "${YELLOW}Please reboot and re-enter U-Boot to flash firmware.${NC}"
        ;;
        
    flash-fw)
        echo -e "${YELLOW}Flashing OpenWrt firmware...${NC}"
        
        if [ -z "$FIRMWARE_FILE" ]; then
            # Try to find firmware file automatically
            FIRMWARE_FILE=$(ls -t bin/targets/mediatek/filogic/*-sl-3000-*-sysupgrade.bin 2>/dev/null | head -1)
            if [ -z "$FIRMWARE_FILE" ]; then
                echo -e "${RED}Error: Please specify firmware file with -f${NC}"
                exit 1
            fi
            echo -e "${BLUE}Auto-detected firmware: $FIRMWARE_FILE${NC}"
        fi
        
        if [ ! -f "$FIRMWARE_FILE" ]; then
            echo -e "${RED}Error: Firmware file not found: $FIRMWARE_FILE${NC}"
            exit 1
        fi
        
        echo "Firmware: $FIRMWARE_FILE"
        echo ""
        echo -e "${YELLOW}Choose flashing method:${NC}"
        echo "1) SSH sysupgrade (for existing OpenWrt)"
        echo "2) U-Boot web interface (for first flash)"
        echo "3) TFTP (advanced)"
        read -p "Enter choice [1-3]: " choice
        
        case $choice in
            1)
                echo "Uploading firmware..."
                scp "$FIRMWARE_FILE" "root@$ROUTER_IP:/tmp/firmware.bin"
                echo "Starting sysupgrade..."
                ssh "root@$ROUTER_IP" "sysupgrade -F /tmp/firmware.bin"
                ;;
            2)
                echo -e "${YELLOW}Please follow these steps:${NC}"
                echo "1. Power off the router"
                echo "2. Hold the Reset button"
                echo "3. Power on and wait for LED to blink"
                echo "4. Release Reset button"
                echo "5. Set your computer IP to 192.168.1.2/24"
                echo "6. Open http://192.168.1.1 in browser"
                echo "7. Upload: $FIRMWARE_FILE"
                echo ""
                read -p "Press Enter when ready to open browser..."
                xdg-open "http://192.168.1.1" 2>/dev/null || \
                    open "http://192.168.1.1" 2>/dev/null || \
                    echo "Please open http://192.168.1.1 manually"
                ;;
            3)
                echo -e "${YELLOW}TFTP flash instructions:${NC}"
                echo "1. Install TFTP server"
                echo "2. Copy firmware to TFTP root directory"
                echo "3. Rename to: openwrt.bin"
                echo "4. Set computer IP to 192.168.1.2/24"
                echo "5. Enter U-Boot command line"
                echo "6. Run: tftpboot 0x46000000 openwrt.bin"
                echo "7. Run: bootm 0x46000000"
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                exit 1
                ;;
        esac
        ;;
        
    setup-docker)
        echo -e "${YELLOW}Setting up Docker data directory...${NC}"
        
        ssh "root@$ROUTER_IP" '
            # Create Docker directory on eMMC
            mkdir -p /opt/docker
            
            # Update Docker daemon config
            cat > /etc/docker/daemon.json << "EOF"
{
    "data-root": "/opt/docker",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF
            
            # Restart Docker
            /etc/init.d/docker restart
            
            echo "Docker data directory set to: /opt/docker"
            df -h /opt
        '
        
        echo -e "${GREEN}Docker setup complete!${NC}"
        ;;
        
    install-ipk)
        echo -e "${YELLOW}Installing .ipk packages...${NC}"
        
        IPK_DIR="${FIRMWARE_FILE:-./ipk}"
        if [ ! -d "$IPK_DIR" ]; then
            echo -e "${RED}Error: Directory not found: $IPK_DIR${NC}"
            exit 1
        fi
        
        echo "Uploading packages..."
        scp "$IPK_DIR"/*.ipk "root@$ROUTER_IP:/tmp/" 2>/dev/null || true
        
        echo "Installing packages..."
        ssh "root@$ROUTER_IP" '
            cd /tmp
            for pkg in *.ipk; do
                if [ -f "$pkg" ]; then
                    echo "Installing: $pkg"
                    opkg install "$pkg" || true
                fi
            done
            rm -f *.ipk
        '
        
        echo -e "${GREEN}Packages installed!${NC}"
        ;;
        
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        show_help
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"
