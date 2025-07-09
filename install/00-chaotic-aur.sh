#!/bin/bash

# Source shared logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"

# Set up error handling
setup_error_handling

# Function to import Chaotic AUR signing keys
import_chaotic_keys() {
    print_status "Importing Chaotic AUR signing keys..."
    
    # Import the primary key
    if sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com; then
        print_status "Successfully imported primary key"
    else
        print_error "Failed to import primary key"
        return 1
    fi
    
    # Sign the key locally
    if sudo pacman-key --lsign-key 3056513887B78AEB; then
        print_status "Successfully signed key locally"
    else
        print_error "Failed to sign key locally"
        return 1
    fi
    
    print_status "Chaotic AUR signing keys imported successfully"
}

# Function to install chaotic-keyring and chaotic-mirrorlist
install_chaotic_packages() {
    print_status "Installing chaotic-keyring and chaotic-mirrorlist..."
    
    # Install chaotic-keyring and chaotic-mirrorlist
    if sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.xz' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.xz'; then
        print_status "Successfully installed chaotic-keyring and chaotic-mirrorlist"
    else
        print_error "Failed to install chaotic-keyring and chaotic-mirrorlist"
        return 1
    fi
}

# Function to enable chaotic repository in pacman.conf
enable_chaotic_repo() {
    print_status "Enabling Chaotic AUR repository in /etc/pacman.conf..."
    
    # Check if chaotic-aur is already enabled
    if grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
        print_status "Chaotic AUR repository is already enabled"
        return 0
    fi
    
    # Create backup of pacman.conf
    if sudo cp /etc/pacman.conf /etc/pacman.conf.backup.$(date +%Y%m%d_%H%M%S); then
        print_status "Created backup of /etc/pacman.conf"
    else
        print_error "Failed to create backup of /etc/pacman.conf"
        return 1
    fi
    
    # Add chaotic-aur repository to pacman.conf
    if sudo tee -a /etc/pacman.conf > /dev/null << 'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
    then
        print_status "Successfully added Chaotic AUR repository to pacman.conf"
    else
        print_error "Failed to add Chaotic AUR repository to pacman.conf"
        return 1
    fi
    
    # Update package databases
    if sudo pacman -Sy; then
        print_status "Successfully updated package databases"
    else
        print_error "Failed to update package databases"
        return 1
    fi
}

# Function to verify chaotic-aur setup
verify_chaotic_setup() {
    print_status "Verifying Chaotic AUR setup..."
    
    # Check if chaotic-aur repository is available
    if pacman -Sl chaotic-aur &> /dev/null; then
        print_status "Chaotic AUR repository is working correctly"
        # Show some stats
        local pkg_count=$(pacman -Sl chaotic-aur | wc -l)
        print_status "Available packages in chaotic-aur: $pkg_count"
        return 0
    else
        print_error "Chaotic AUR repository is not working properly"
        return 1
    fi
}

# Main installation process
echo "=== Chaotic AUR Repository Setup ==="
echo

# Check if already configured
if grep -q "^\[chaotic-aur\]" /etc/pacman.conf && pacman -Sl chaotic-aur &> /dev/null; then
    print_status "Chaotic AUR repository is already configured and working"
    verify_chaotic_setup
    exit 0
fi

# Prompt user for confirmation
if command -v gum > /dev/null 2>&1; then
    if ! gum confirm "Set up Chaotic AUR repository? This will import signing keys and modify /etc/pacman.conf"; then
        print_warning "Skipping Chaotic AUR setup"
        exit 0
    fi
else
    echo -n "Set up Chaotic AUR repository? This will import signing keys and modify /etc/pacman.conf (y/N): "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            print_status "Setting up Chaotic AUR..."
            ;;
        *)
            print_warning "Skipping Chaotic AUR setup"
            exit 0
            ;;
    esac
fi

# Import signing keys
if ! import_chaotic_keys; then
    print_error "Failed to import Chaotic AUR signing keys"
    exit 1
fi

# Install chaotic packages
if ! install_chaotic_packages; then
    print_error "Failed to install chaotic packages"
    exit 1
fi

# Enable chaotic repository
if ! enable_chaotic_repo; then
    print_error "Failed to enable Chaotic AUR repository"
    exit 1
fi

# Verify setup
if verify_chaotic_setup; then
    print_status "Chaotic AUR setup completed successfully!"
    print_status "You can now install packages from the Chaotic AUR using pacman"
    print_status "Example: sudo pacman -S package-name"
else
    print_error "Chaotic AUR setup completed but verification failed"
    exit 1
fi
