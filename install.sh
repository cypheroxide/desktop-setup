#!/bin/bash

# Source shared logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"

# Set up error handling
setup_error_handling

# Default configuration
AUR_HELPER="yay"
DRY_RUN=false
VERBOSE=false

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -a, --aur-helper HELPER    Choose AUR helper: yay, paru, trizen (default: yay)"
    echo "  -d, --dry-run              Show what would be installed without actually installing"
    echo "  -v, --verbose              Enable verbose output"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Supported AUR helpers:"
    echo "  yay     - Default, feature-rich AUR helper"
    echo "  paru    - Rust-based AUR helper"
    echo "  trizen  - Lightweight AUR helper"
    echo ""
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--aur-helper)
                AUR_HELPER="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate AUR helper choice
    case "$AUR_HELPER" in
        yay|paru|trizen)
            log "Selected AUR helper: $AUR_HELPER"
            ;;
        *)
            log_error "Unsupported AUR helper: $AUR_HELPER"
            log_error "Supported options: yay, paru, trizen"
            exit 1
            ;;
    esac
}

# Function to prompt for AUR helper selection
select_aur_helper() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Skipping AUR helper selection"
        return 0
    fi
    
    echo -e "${YELLOW}Choose AUR helper:${NC}"
    echo "1. yay (default, feature-rich AUR helper)"
    echo "2. paru (rust-based AUR helper)"
    echo "3. trizen (lightweight AUR helper)"
    echo ""
    
    if command -v gum > /dev/null 2>&1; then
        # Use gum for better interface
        local choice
        choice=$(gum choose "yay" "paru" "trizen" --header "Choose AUR helper:" --selected "yay")
        AUR_HELPER="$choice"
    else
        # Fallback to read prompt
        local choice
        read -p "Enter your choice (1 for yay, 2 for paru, 3 for trizen) [1]: " choice
        
        case "$choice" in
            1|"")
                AUR_HELPER="yay"
                ;;
            2)
                AUR_HELPER="paru"
                ;;
            3)
                AUR_HELPER="trizen"
                ;;
            yay)
                AUR_HELPER="yay"
                ;;
            paru)
                AUR_HELPER="paru"
                ;;
            trizen)
                AUR_HELPER="trizen"
                ;;
            *)
                log_warning "Invalid choice '$choice'. Defaulting to yay."
                AUR_HELPER="yay"
                ;;
        esac
    fi
    
    log "Selected AUR helper: $AUR_HELPER"
}

# Function to install AUR helper if not present
install_aur_helper() {
    if command -v "$AUR_HELPER" > /dev/null 2>&1; then
        log "$AUR_HELPER is already installed"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would install $AUR_HELPER"
        return 0
    fi
    
    log "Installing $AUR_HELPER..."
    
    # Ensure base-devel is installed
    if ! pacman -Qi base-devel &> /dev/null; then
        log "Installing base-devel (required for AUR packages)..."
        sudo pacman -S --needed --noconfirm base-devel
    fi
    
    # Install git if not present
    if ! command -v git > /dev/null 2>&1; then
        log "Installing git (required for AUR helper installation)..."
        sudo pacman -S --needed --noconfirm git
    fi
    
    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    local original_dir="$PWD"
    
    cd "$temp_dir" || {
        log_error "Failed to create temporary directory"
        return 1
    }
    
    case "$AUR_HELPER" in
        yay)
            log "Cloning yay-bin from AUR..."
            if git clone https://aur.archlinux.org/yay-bin.git; then
                cd yay-bin || return 1
                makepkg -si --noconfirm
                log_success "yay installed successfully"
            else
                log_error "Failed to clone yay-bin repository"
                cd "$original_dir"
                rm -rf "$temp_dir"
                return 1
            fi
            ;;
        paru)
            log "Cloning paru-bin from AUR..."
            if git clone https://aur.archlinux.org/paru-bin.git; then
                cd paru-bin || return 1
                makepkg -si --noconfirm
                log_success "paru installed successfully"
            else
                log_error "Failed to clone paru-bin repository"
                cd "$original_dir"
                rm -rf "$temp_dir"
                return 1
            fi
            ;;
        trizen)
            log "Cloning trizen from AUR..."
            if git clone https://aur.archlinux.org/trizen.git; then
                cd trizen || return 1
                makepkg -si --noconfirm
                log_success "trizen installed successfully"
            else
                log_error "Failed to clone trizen repository"
                cd "$original_dir"
                rm -rf "$temp_dir"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported AUR helper: $AUR_HELPER"
            cd "$original_dir"
            rm -rf "$temp_dir"
            return 1
            ;;
    esac
    
    # Clean up
    cd "$original_dir"
    rm -rf "$temp_dir"
    
    # Verify installation
    if command -v "$AUR_HELPER" > /dev/null 2>&1; then
        log_success "$AUR_HELPER installation completed successfully"
        "$AUR_HELPER" --version
    else
        log_error "$AUR_HELPER installation failed"
        return 1
    fi
}

# Parse command line arguments
parse_arguments "$@"

# Main script logic starts here
log "Consolidated installation script started"

if [[ "$VERBOSE" == "true" ]]; then
    log "Configuration:"
    log "  AUR Helper: $AUR_HELPER"
    log "  Dry Run: $DRY_RUN"
    log "  Verbose: $VERBOSE"
fi

if [[ "$DRY_RUN" == "true" ]]; then
    log "[DRY RUN] This is a dry run - no actual installation will be performed"
fi

# Prompt for AUR helper selection if using default or no specific helper specified
if [[ -z "$AUR_HELPER" || "$AUR_HELPER" == "yay" ]]; then
    select_aur_helper
fi

# Install the selected AUR helper if not already present
install_aur_helper

# Export AUR helper for use in subsequent modules
export AUR_HELPER

log_success "AUR helper setup completed successfully"

# Function to run installation modules
run_install_module() {
    local module="$1"
    local module_path="$SCRIPT_DIR/install/$module"
    
    if [[ -f "$module_path" && -x "$module_path" ]]; then
        log "[$module] Starting installation module"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "[DRY RUN] Would execute: $module_path"
            return 0
        fi
        
        # Export AUR helper preference for modules to use
        export AUR_HELPER
        export VERBOSE
        
        # Source the module with error handling
        if [[ "$VERBOSE" == "true" ]]; then
            log "[DEBUG] Sourcing module: $module_path"
        fi
        
        if source "$module_path"; then
            log_success "[$module] Module completed successfully"
        else
            log_error "[$module] Module failed to execute"
            return 1
        fi
    else
        log_warning "[$module] Module not found or not executable, skipping"
    fi
}

# Function to execute all installation modules
execute_installation_modules() {
    log "Starting installation process..."
    
    # Check if install directory exists
    if [[ ! -d "$SCRIPT_DIR/install" ]]; then
        log_error "Install directory not found: $SCRIPT_DIR/install"
        exit 1
    fi
    
    # Find all .sh files in install directory and sort them numerically
    local install_scripts
    install_scripts=$(find "$SCRIPT_DIR/install" -name "*.sh" -type f | sort -V)
    
    if [[ -z "$install_scripts" ]]; then
        log_warning "No installation scripts found in install/ directory"
        return 0
    fi
    
    log "Found the following installation scripts:"
    echo "$install_scripts" | sed 's/^/  - /' | sed "s|$SCRIPT_DIR/install/||g"
    echo
    
    # Execute each script in order
    local script_count=0
    local total_scripts=$(echo "$install_scripts" | wc -l)
    
    while IFS= read -r script_path; do
        script_count=$((script_count + 1))
        local script_name=$(basename "$script_path")
        
        log "[$script_count/$total_scripts] Processing: $script_name"
        
        # Check if script is executable
        if [[ ! -x "$script_path" ]]; then
            log_warning "Making $script_name executable..."
            chmod +x "$script_path"
        fi
        
        # Run the installation module
        run_install_module "$script_name"
        
        echo # Add spacing between scripts
        
    done <<< "$install_scripts"
    
    log_success "All installation modules completed successfully!"
}

# Function to get user confirmation
get_user_confirmation() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Skipping user confirmation"
        return 0
    fi
    
    echo -e "${YELLOW}This will install and configure the desktop environment with:${NC}"
    echo "  - $AUR_HELPER AUR helper"
    echo "  - Core development tools"
    echo "  - KDE Plasma desktop with plasmoids"
    echo "  - Flatpak applications"
    echo "  - Docker containers (Media server, Development environment)"
    echo "  - Development tools and utilities"
    echo "  - System configuration and themes"
    echo "  - ZSH with Powerlevel10k theme"
    echo
    
    if command -v gum > /dev/null 2>&1; then
        gum confirm "Continue with installation?" || {
            log "Installation cancelled by user."
            exit 0
        }
    else
        read -p "Continue with installation? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Installation cancelled by user."
            exit 0
        fi
    fi
}

# Get user confirmation
get_user_confirmation

# Execute installation modules
execute_installation_modules

log_success "Desktop setup installation completed successfully!"

# Update file database
update_file_database() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would update file database"
        return 0
    fi

    log "Updating file database..."
    if command -v updatedb > /dev/null 2>&1; then
        if sudo updatedb; then
            log_success "File database updated successfully"
        else
            log_warning "Failed to update file database, but continuing..."
        fi
    else
        log_warning "updatedb command not found, skipping database update"
    fi
}

# Function to apply configurations
apply_configurations() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would apply configurations"
        return 0
    fi

    log "Checking for configuration files..."
    
    if [[ -d "$SCRIPT_DIR/config" ]]; then
        log "Configuration files available in $SCRIPT_DIR/config/"
        log "Note: Configuration files may need to be applied manually"
    else
        log_warning "No configuration directory found"
    fi
}

# Function to display final summary with updated information
show_final_summary() {
    echo
    log_success "Installation process completed successfully!"
    
    echo "Summary:"
    echo "  - Desktop environment: KDE Plasma"
    echo "  - Shell: ZSH with Powerlevel10k"
    echo "  - Package manager: $AUR_HELPER (AUR)"
    echo "  - Configurations: Available in config/ directory"
    echo "  - Custom scripts: Available in bin/ directory"
    echo "  - File database: Updated"
    echo
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}DRY RUN COMPLETED - No actual changes were made${NC}"
    else
        echo -e "${YELLOW}Next steps:${NC}"
        echo "1. Apply configuration files from config/ directory"
        echo "2. Review any configuration files that may need customization"
        echo "3. Restart your session or reboot to apply all changes"
        echo "4. Check individual module logs above for any issues"
    fi
    
    echo
    echo "Enjoy your new desktop setup!"
}

# Function to offer reboot at the end of the installation
offer_reboot() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Skipping reboot prompt"
        return 0
    fi

    echo
    echo "Installation completed successfully!"
    echo
    echo "System reboot options:"
    echo "  - Rebooting ensures all kernel modules and system services are properly loaded"
    echo "  - Some desktop environment changes may require a session restart"
    echo

    # Ask user about reboot
    while true; do
        read -p "Would you like to reboot now? (y/n): " -n 1 -r
        echo
        case $REPLY in
            [Yy]*)
                log "Rebooting system..."
                sudo reboot
                break
                ;;
            [Nn]*)
                log "Reboot skipped. Please remember to reboot manually when convenient."
                break
                ;;
            *)
                echo "Please answer y or n."
                ;;
        esac
    done

    log "Installation process finished!"
}

# Apply configurations
apply_configurations

# Update file database
update_file_database

# Show final summary
show_final_summary

# Offer reboot prompt
offer_reboot
