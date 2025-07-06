#!/bin/bash

# KDE Plasma Desktop Installation Script
# This script installs and configures KDE Plasma desktop environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if gum is available
if ! command -v gum &> /dev/null; then
    print_error "gum is not installed. Please install it first."
    exit 1
fi

print_status "Starting KDE Plasma desktop installation..."

# Install KDE Plasma and related packages
print_status "Installing KDE Plasma packages..."
sudo pacman -S --needed plasma sddm kde-applications

if [[ $? -eq 0 ]]; then
    print_success "KDE Plasma packages installed successfully"
else
    print_error "Failed to install KDE Plasma packages"
    exit 1
fi

# Create config directory if it doesn't exist
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

if [[ ! -d "$CONFIG_DIR" ]]; then
    mkdir -p "$CONFIG_DIR"
    print_status "Created config directory: $CONFIG_DIR"
fi

# Copy default Plasma configuration
print_status "Copying default Plasma configuration..."

# Create plasma config directory
mkdir -p "$CONFIG_DIR/plasma"

# Copy default KDE configuration files if they exist
if [[ -d "/usr/share/plasma" ]]; then
    print_status "Copying default Plasma configurations..."
    
    # Copy default plasma configuration
    if [[ -d "/usr/share/plasma/shells" ]]; then
        cp -r /usr/share/plasma/shells "$CONFIG_DIR/plasma/" 2>/dev/null || true
    fi
    
    # Copy default plasmoids
    if [[ -d "/usr/share/plasma/plasmoids" ]]; then
        cp -r /usr/share/plasma/plasmoids "$CONFIG_DIR/plasma/" 2>/dev/null || true
    fi
    
    # Copy default look and feel
    if [[ -d "/usr/share/plasma/look-and-feel" ]]; then
        cp -r /usr/share/plasma/look-and-feel "$CONFIG_DIR/plasma/" 2>/dev/null || true
    fi
fi

# Copy default KDE application configurations
if [[ -d "/usr/share/config" ]]; then
    print_status "Copying default KDE application configurations..."
    cp -r /usr/share/config/* "$CONFIG_DIR/" 2>/dev/null || true
fi

# Create a basic plasma configuration template
cat > "$CONFIG_DIR/plasma/plasma-org.kde.plasma.desktop-appletsrc" << 'EOF'
[ActionPlugins][0]
RightButton;NoModifier=org.kde.contextmenu

[ActionPlugins][1]
RightButton;NoModifier=org.kde.contextmenu

[Containments][1]
activityId=
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.plasma.folder
wallpaperplugin=org.kde.image

[Containments][1][Wallpaper][org.kde.image][General]
Image=file:///usr/share/wallpapers/Next/contents/images/1920x1080.png
SlidePaths=/usr/share/wallpapers/

[Containments][2]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=3
plugin=org.kde.plasma.panel
wallpaperplugin=org.kde.image

[Containments][2][Applets][3]
immutability=1
plugin=org.kde.plasma.kickoff

[Containments][2][Applets][4]
immutability=1
plugin=org.kde.plasma.pager

[Containments][2][Applets][5]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][2][Applets][6]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][2][General]
AppletOrder=3,4,5,6

[General]
immutability=1
EOF

print_success "Default Plasma configuration copied to $CONFIG_DIR"

# Ask user if they want to enable the display manager
print_status "SDDM (Simple Desktop Display Manager) configuration..."

if gum confirm "Do you want to enable and start SDDM display manager now?"; then
    print_status "Enabling SDDM display manager..."
    
    # Enable SDDM service
    sudo systemctl enable sddm.service
    
    if [[ $? -eq 0 ]]; then
        print_success "SDDM service enabled successfully"
        
        # Ask if user wants to start it immediately
        if gum confirm "Do you want to start SDDM now? (This will switch to graphical login)"; then
            print_warning "Starting SDDM will switch to graphical mode..."
            sudo systemctl start sddm.service
            print_success "SDDM started successfully"
        else
            print_status "SDDM enabled but not started. You can start it later with: sudo systemctl start sddm.service"
        fi
    else
        print_error "Failed to enable SDDM service"
        exit 1
    fi
else
    print_status "SDDM not enabled. You can enable it later with: sudo systemctl enable sddm.service"
fi

# Create a basic SDDM configuration
print_status "Creating SDDM configuration..."
sudo mkdir -p /etc/sddm.conf.d

sudo tee /etc/sddm.conf.d/kde_settings.conf > /dev/null << 'EOF'
[Autologin]
# Relogin=false
# Session=
# User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
# Current theme name
Current=breeze

[Users]
# Maximum user id for displayed users
MaximumUid=60000
# Minimum user id for displayed users
MinimumUid=1000
EOF

print_success "SDDM configuration created at /etc/sddm.conf.d/kde_settings.conf"

print_success "KDE Plasma installation completed successfully!"
print_status "Next steps:"
print_status "1. The desktop environment is now installed"
print_status "2. Configuration files are available in: $CONFIG_DIR"
print_status "3. You can customize the desktop after first login"
print_status "4. To start the graphical session: sudo systemctl start sddm.service"

echo
print_status "Installation summary:"
print_status "- KDE Plasma desktop environment: ✓ Installed"
print_status "- SDDM display manager: ✓ Installed"
print_status "- KDE Applications: ✓ Installed"
print_status "- Default configurations: ✓ Copied to config/"
print_status "- SDDM service: $(systemctl is-enabled sddm.service 2>/dev/null || echo 'disabled')"
