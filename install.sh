#!/bin/bash

# Desktop Setup Main Installation Script
# This script orchestrates the installation of various components

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source colors and utility functions
if [[ -f "$SCRIPT_DIR/bin/colors.sh" ]]; then
    source "$SCRIPT_DIR/bin/colors.sh"
else
    # Basic color definitions if utility script doesn't exist
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
fi

echo -e "${BLUE}=== Desktop Setup Installation ===${NC}"
echo "Project directory: $SCRIPT_DIR"
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${YELLOW}Warning: Running as root. Some operations may behave differently.${NC}"
fi

# Function to run installation modules
run_install_module() {
    local module="$1"
    local module_path="$SCRIPT_DIR/install/$module"
    
    if [[ -f "$module_path" && -x "$module_path" ]]; then
        echo -e "${BLUE}Running installation module: $module${NC}"
        "$module_path"
        echo -e "${GREEN}Module $module completed successfully${NC}"
    else
        echo -e "${YELLOW}Module $module not found or not executable, skipping${NC}"
    fi
}

# Check if user wants to proceed
echo -e "${YELLOW}This will install and configure the desktop environment with:${NC}"
echo "  - YAY AUR helper"
echo "  - Core development tools"
echo "  - KDE Plasma desktop with plasmoids"
echo "  - Flatpak applications"
echo "  - Docker containers (Media server, Development environment)"
echo "  - Development tools and utilities"
echo "  - System configuration and themes"
echo "  - ZSH with Powerlevel10k theme"
echo
read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Main installation process
echo -e "${BLUE}Starting installation process...${NC}"
echo

# Install components in order
run_install_module "01-yay.sh"
run_install_module "02-core-dev-tools.sh"
run_install_module "03-kde-plasma.sh"
run_install_module "04-flatpaks.sh"
run_install_module "05-docker-containers.sh"
run_install_module "06-dev-tools-utilities.sh"
run_install_module "07-system-config-themes.sh"

# Apply configurations
echo -e "${BLUE}Applying configurations...${NC}"
if [[ -d "$SCRIPT_DIR/config" ]]; then
    echo "Configuration files available in $SCRIPT_DIR/config/"
    echo "Run individual config installation commands as needed."
fi

echo
echo -e "${GREEN}Installation process completed successfully!${NC}"
echo "Summary:"
echo "  - Desktop environment: KDE Plasma"
echo "  - Shell: ZSH with Powerlevel10k"
echo "  - Package manager: YAY (AUR)"
echo "  - Configurations: Available in config/ directory"
echo "  - Custom scripts: Available in bin/ directory"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Apply configuration files from config/ directory"
echo "2. Restart your session to apply all changes"
echo "3. Check individual module logs above for any issues"
echo
echo "Enjoy your new desktop setup!"
