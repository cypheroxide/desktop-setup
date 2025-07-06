#!/bin/bash

# Test script for AUR helper selection functionality

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Main test function
main() {
    log "Testing AUR helper selection functionality..."
    
    # Test the selection function
    select_aur_helper
    
    # Verify the variable is set
    if [[ -n "$AUR_HELPER" ]]; then
        log_success "AUR_HELPER variable is set to: $AUR_HELPER"
    else
        log_error "AUR_HELPER variable is not set"
        exit 1
    fi
    
    # Test command construction
    log "Testing command construction..."
    local test_command="$AUR_HELPER -S --needed package-name"
    log "Test command: $test_command"
    
    # Check if AUR helper is available
    if command -v "$AUR_HELPER" > /dev/null 2>&1; then
        log_success "$AUR_HELPER is installed and available"
        "$AUR_HELPER" --version
    else
        log_warning "$AUR_HELPER is not currently installed"
        log "Command that would be used to install packages: $test_command"
    fi
    
    log_success "Test completed successfully!"
}

# Run the test
main "$@"
