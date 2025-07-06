#!/bin/bash

# Chaotic AUR Installation Script
# This script automates the setup of the Chaotic AUR repository
# for Arch Linux systems.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user."
        exit 1
    fi
}

# Function to check if pacman is available
check_pacman() {
    if ! command -v pacman &> /dev/null; then
        print_error "pacman not found. This script is only for Arch Linux systems."
        exit 1
    fi
}

# Function to add chaotic-aur repository to pacman.conf
add_chaotic_repo() {
    print_status "Adding Chaotic AUR repository to /etc/pacman.conf..."
    
    # Check if chaotic-aur is already configured
    if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        print_warning "Chaotic AUR repository already exists in /etc/pacman.conf"
        return 0
    fi
    
    # Add chaotic-aur repository
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
    print_success "Chaotic AUR repository added to pacman.conf"
}

# Main installation function
install_chaotic_aur() {
    print_status "Starting Chaotic AUR installation..."
    echo
    
    # Step 1: Import the primary key
    print_status "Step 1: Importing Chaotic AUR primary key..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    
    # Step 2: Locally sign the key
    print_status "Step 2: Locally signing the imported key..."
    sudo pacman-key --lsign-key 3056513887B78AEB
    
    print_success "Key setup completed successfully"
    echo
    
    # Step 3: Install chaotic-keyring and chaotic-mirrorlist
    print_status "Step 3: Installing chaotic-keyring and chaotic-mirrorlist packages..."
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    
    print_success "Chaotic AUR packages installed successfully"
    echo
    
    # Step 4: Add repository to pacman.conf
    add_chaotic_repo
    echo
    
    # Step 5: Update system
    print_status "Step 5: Updating system and synchronizing with Chaotic AUR..."
    sudo pacman -Syu --noconfirm
    
    print_success "System update completed"
    echo
    
    print_success "🎉 Chaotic AUR installation completed successfully!"
    print_status "You can now install packages from the Chaotic AUR using: pacman -S <package-name>"
    print_status "Popular packages include: yay, paru, google-chrome, visual-studio-code-bin"
}

# Error handling function
cleanup() {
    print_error "An error occurred during installation. Please check the output above."
    exit 1
}

# Set up error handling
trap cleanup ERR

# Main execution
echo "==============================================="
echo "    Chaotic AUR Installation Script"
echo "==============================================="
echo

# Perform checks
check_root
check_pacman

# Ask for confirmation
print_status "This script will install and configure the Chaotic AUR repository."
print_warning "This will modify your /etc/pacman.conf file and install packages."
echo
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Installation cancelled by user."
    exit 0
fi

echo
install_chaotic_aur
