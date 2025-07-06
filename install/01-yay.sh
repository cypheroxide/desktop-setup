#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to install base-devel
install_base_devel() {
    print_status "Installing base-devel package group..."
    if sudo pacman -S --needed --noconfirm base-devel; then
        print_status "base-devel installed successfully"
    else
        print_error "Failed to install base-devel"
        exit 1
    fi
}

# Function to install yay
install_yay() {
    print_status "Installing yay AUR helper..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || exit 1
    
    # Clone yay-bin from AUR
    if git clone https://aur.archlinux.org/yay-bin.git; then
        print_status "Successfully cloned yay-bin repository"
    else
        print_error "Failed to clone yay-bin repository"
        exit 1
    fi
    
    cd yay-bin || exit 1
    
    # Build and install yay
    if makepkg -si --noconfirm; then
        print_status "yay installed successfully"
    else
        print_error "Failed to build and install yay"
        exit 1
    fi
    
    # Clean up
    cd /
    rm -rf "$TEMP_DIR"
    print_status "Cleaned up temporary files"
}

# Main installation process
echo "=== AUR Helper (yay) Installation ==="
echo

# Check if base-devel is needed
if ! pacman -Qi base-devel &> /dev/null; then
    if gum confirm "Install base-devel package group? (Required for building AUR packages)"; then
        install_base_devel
    else
        print_warning "Skipping base-devel installation. This may cause issues with AUR package building."
    fi
else
    print_status "base-devel is already installed"
fi

# Check for yay
if ! command -v yay &> /dev/null; then
    if gum confirm "Yay not found. Install yay AUR helper?"; then
        install_yay
        print_status "yay installation completed!"
    else
        print_warning "Skipping yay installation."
        exit 0
    fi
else
    print_status "yay is already installed"
    yay --version
fi

print_status "AUR helper setup complete!"
