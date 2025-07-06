#!/bin/bash

# Main installer orchestrator script
# This script executes all installation scripts in the install/ directory in numeric order

# Exit on any error
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Error trap function
error_trap() {
    local exit_code=$?
    local line_number=$1
    log_error "Script failed at line $line_number with exit code $exit_code"
    log_error "Installation aborted!"
    exit $exit_code
}

# Set up error trap
trap 'error_trap $LINENO' ERR

# Function to prompt for AUR helper selection
select_aur_helper() {
    echo -e "${YELLOW}Choose AUR helper:${NC}"
    echo "1. yay (default, feature-rich AUR helper)"
    echo "2. paru (rust-based AUR helper)"
    echo ""
    
    if command -v gum > /dev/null 2>&1; then
        # Use gum for better interface
        local choice
        choice=$(gum choose "yay" "paru" --header "Choose AUR helper:" --selected "yay")
        AUR_HELPER="$choice"
    else
        # Fallback to read prompt
        local choice
        read -p "Enter your choice (1 for yay, 2 for paru) [1]: " choice
        
        case "$choice" in
            1|"")
                AUR_HELPER="yay"
                ;;
            2)
                AUR_HELPER="paru"
                ;;
            yay)
                AUR_HELPER="yay"
                ;;
            paru)
                AUR_HELPER="paru"
                ;;
            *)
                log_warning "Invalid choice '$choice'. Defaulting to yay."
                AUR_HELPER="yay"
                ;;
        esac
    fi
    
    log "Selected AUR helper: $AUR_HELPER"
    export AUR_HELPER
}

# Main installation function
main() {
    log "Starting installation process..."
    
    # Select AUR helper
    select_aur_helper
    
    # Check if install directory exists
    if [ ! -d "install" ]; then
        log_error "Install directory not found!"
        log_error "Please ensure you're running this script from the correct location."
        exit 1
    fi
    
    # Find all .sh files in install directory and sort them numerically
    local install_scripts
    install_scripts=$(find install -name "*.sh" -type f | sort -V)
    
    if [ -z "$install_scripts" ]; then
        log_warning "No installation scripts found in install/ directory"
        exit 0
    fi
    
    log "Found the following installation scripts:"
    echo "$install_scripts" | sed 's/^/  - /'
    echo
    
    # Execute each script in order
    local script_count=0
    local total_scripts=$(echo "$install_scripts" | wc -l)
    
    while IFS= read -r script; do
        script_count=$((script_count + 1))
        
        log "[$script_count/$total_scripts] Executing: $script"
        
        # Check if script is executable
        if [ ! -x "$script" ]; then
            log_warning "Making $script executable..."
            chmod +x "$script"
        fi
        
        # Source the script with error handling
        if source "$script"; then
            log_success "Completed: $script"
        else
            log_error "Failed to execute: $script"
            exit 1
        fi
        
        echo # Add spacing between scripts
        
    done <<< "$install_scripts"
    
    log_success "All installation scripts completed successfully!"
    
    # Update file database
    log "Updating file database..."
    if command -v updatedb >/dev/null 2>&1; then
        if sudo updatedb; then
            log_success "File database updated successfully"
        else
            log_warning "Failed to update file database, but continuing..."
        fi
    else
        log_warning "updatedb command not found, skipping database update"
    fi
    
    # Prompt user for next steps
    echo
    log "Installation completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Review any configuration files that may need customization"
    echo "2. Consider rebooting your system to ensure all changes take effect"
    echo
    
    # Ask user about reboot
    while true; do
        read -p "Would you like to reboot now? (y/n): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* ) 
                log "Rebooting system..."
                sudo reboot
                break
                ;;
            [Nn]* ) 
                log "Reboot skipped. Please remember to reboot manually when convenient."
                break
                ;;
            * ) 
                echo "Please answer y or n."
                ;;
        esac
    done
    
    log "Installation process finished!"
}

# Script entry point
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_warning "Running as root. Some scripts may not work correctly."
        log_warning "Consider running as a regular user with sudo privileges."
    fi
    
    # Run main function
    main "$@"
fi
