#!/bin/bash
# system-update.sh - Comprehensive system update script for Arch Linux
# Usage: ./system-update.sh [--skip-flatpak] [--skip-aur] [--auto-restart]

set -e

# Parse command line arguments
SKIP_FLATPAK=false
SKIP_AUR=false
AUTO_RESTART=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-flatpak)
            SKIP_FLATPAK=true
            shift
            ;;
        --skip-aur)
            SKIP_AUR=true
            shift
            ;;
        --auto-restart)
            AUTO_RESTART=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--skip-flatpak] [--skip-aur] [--auto-restart]"
            echo "  --skip-flatpak  Skip Flatpak updates"
            echo "  --skip-aur      Skip AUR updates"
            echo "  --auto-restart  Automatically restart if kernel was updated"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Source shared logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"

# Set up error handling
setup_error_handling

# Override print_header to use UPDATE prefix
print_header() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] UPDATE:${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
fi

# Store current kernel version
CURRENT_KERNEL=$(uname -r)

print_header "Starting system update process"
print_status "Current kernel: $CURRENT_KERNEL"

# Update package databases
print_header "Updating package databases"
sudo pacman -Sy

# Update system packages
print_header "Updating system packages"
sudo pacman -Syu --noconfirm

# Update AUR packages if yay is installed and not skipped
if command -v yay &> /dev/null && [ "$SKIP_AUR" = false ]; then
    print_header "Updating AUR packages"
    yay -Syu --noconfirm
elif [ "$SKIP_AUR" = false ]; then
    print_warning "yay not found, skipping AUR updates"
fi

# Update Flatpak applications if not skipped
if command -v flatpak &> /dev/null && [ "$SKIP_FLATPAK" = false ]; then
    print_header "Updating Flatpak applications"
    flatpak update -y
elif [ "$SKIP_FLATPAK" = false ]; then
    print_warning "flatpak not found, skipping Flatpak updates"
fi

# Clean package cache
print_header "Cleaning package cache"
sudo pacman -Sc --noconfirm

# Clean AUR cache if yay is installed
if command -v yay &> /dev/null; then
    print_status "Cleaning AUR cache"
    yay -Sc --noconfirm
fi

# Update locate database
if command -v updatedb &> /dev/null; then
    print_header "Updating locate database"
    sudo updatedb
fi

# Update man pages database
if command -v mandb &> /dev/null; then
    print_header "Updating man pages database"
    sudo mandb
fi

# Check for kernel updates
NEW_KERNEL=$(pacman -Q linux 2>/dev/null | awk '{print $2}' || echo "unknown")
if [ "$NEW_KERNEL" != "unknown" ]; then
    print_status "Installed kernel version: $NEW_KERNEL"
    
    # Check if kernel was updated
    if [ "$CURRENT_KERNEL" != "$(uname -r)" ] || pacman -Qu | grep -q "linux "; then
        print_warning "Kernel update detected. System restart recommended."
        
        if [ "$AUTO_RESTART" = true ]; then
            print_status "Auto-restart enabled. Restarting in 30 seconds..."
            print_status "Press Ctrl+C to cancel"
            sleep 30
            sudo reboot
        else
            read -p "Would you like to restart now? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo reboot
            fi
        fi
    fi
fi

# Check for failed systemd services
print_header "Checking for failed systemd services"
FAILED_SERVICES=$(systemctl --failed --no-legend --no-pager | wc -l)
if [ "$FAILED_SERVICES" -gt 0 ]; then
    print_warning "Found $FAILED_SERVICES failed systemd services:"
    systemctl --failed --no-pager
else
    print_status "No failed systemd services found"
fi

# Check disk space
print_header "Checking disk space"
df -h | grep -E "(/$|/home|/var)" | while read line; do
    USAGE=$(echo $line | awk '{print $5}' | sed 's/%//')
    MOUNT=$(echo $line | awk '{print $6}')
    
    if [ "$USAGE" -gt 90 ]; then
        print_warning "Disk usage for $MOUNT is at $USAGE%"
    else
        print_status "Disk usage for $MOUNT: $USAGE%"
    fi
done

# Check for orphaned packages
print_header "Checking for orphaned packages"
ORPHANS=$(pacman -Qtdq 2>/dev/null | wc -l)
if [ "$ORPHANS" -gt 0 ]; then
    print_warning "Found $ORPHANS orphaned packages"
    print_status "To remove them, run: sudo pacman -Rns \$(pacman -Qtdq)"
else
    print_status "No orphaned packages found"
fi

print_header "System update completed successfully!"
print_status "Update finished at: $(date)"

# Optional: Show update summary
print_header "Update Summary"
print_status "Package updates: $(journalctl -u packagekit --since "1 hour ago" | grep -c "installed" || echo "0")"
print_status "Current uptime: $(uptime -p)"
print_status "System load: $(uptime | awk -F'load average:' '{print $2}')"
