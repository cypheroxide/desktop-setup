#!/bin/bash

# Source shared logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"

# Set up error handling
setup_error_handling

# Use AUR_HELPER environment variable, fallback to yay
AUR_HELPER=${AUR_HELPER:-yay}

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

# Function to install AUR helper
install_aur_helper() {
    print_status "Installing $AUR_HELPER AUR helper..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || exit 1
    
    case "$AUR_HELPER" in
        yay)
            # Clone yay-bin from AUR
            if git clone https://aur.archlinux.org/yay-bin.git; then
                print_status "Successfully cloned yay-bin repository"
            else
                print_error "Failed to clone yay-bin repository"
                exit 1
            fi
            
            cd yay-bin || exit 1
            ;;
        paru)
            # Clone paru-bin from AUR
            if git clone https://aur.archlinux.org/paru-bin.git; then
                print_status "Successfully cloned paru-bin repository"
            else
                print_error "Failed to clone paru-bin repository"
                exit 1
            fi
            
            cd paru-bin || exit 1
            ;;
        *)
            print_error "Unsupported AUR helper: $AUR_HELPER"
            exit 1
            ;;
    esac
    
    # Build and install AUR helper
    if makepkg -si --noconfirm; then
        print_status "$AUR_HELPER installed successfully"
    else
        print_error "Failed to build and install $AUR_HELPER"
        exit 1
    fi
    
    # Clean up
    cd /
    rm -rf "$TEMP_DIR"
    print_status "Cleaned up temporary files"
}

# Main installation process
echo "=== AUR Helper ($AUR_HELPER) Installation ==="
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

# Check for selected AUR helper
if ! command -v "$AUR_HELPER" &> /dev/null; then
    if gum confirm "$AUR_HELPER not found. Install $AUR_HELPER AUR helper?"; then
        install_aur_helper
        print_status "$AUR_HELPER installation completed!"
    else
        print_warning "Skipping $AUR_HELPER installation."
        exit 0
    fi
else
    print_status "$AUR_HELPER is already installed"
    "$AUR_HELPER" --version
fi

print_status "AUR helper ($AUR_HELPER) setup complete!"
