#!/bin/bash

# Desktop Setup Bootstrap Script
# This script initializes the desktop setup process with enhanced error handling and interactive prompts

# Set strict error handling
set -euo pipefail

# Global configuration
DESKTOP_REF="${DESKTOP_REF:-main}"
REPO_URL="${REPO_URL:-https://github.com/your-username/desktop-setup.git}"
REPO_PATH="$HOME/.local/share/desktop-setup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
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

# Function to display ASCII banner
show_banner() {
    echo "  _____            _        _                          _     "
    echo " |  __ \\          | |      | |                        | |    "
    echo " | |  | | ___  ___| |_     | |__   ___  _   _ ___  ___| |__  "
    echo " | |  | |/ _ \\/ __| __|    | '_ \\ / _ \\| | | / __|/ _ \\ '_ \\ "
    echo " | |__| |  __/\\__ \\ |_ _   | | | | (_) | |_| \\__ \\  __/ |_) |"
    echo " |_____/ \\___||___/\\__( )  |_| |_|\\___/ \\__,_|___/\\___|_.__/ "
    echo "                      |/                                    "
    echo ""
    echo "Desktop Setup Bootstrap"
    echo "======================="
    echo ""
    log "Project directory: $SCRIPT_DIR"
    echo ""
}

# Error trap function
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    log_error "Script failed at line $line_number with exit code $exit_code"
    
    if command -v gum > /dev/null 2>&1; then
        gum format --theme=warm "❌ Bootstrap failed! Check the logs above for details."
    else
        echo "❌ Bootstrap failed! Check the logs above for details."
    fi
    
    exit $exit_code
}

# Set error trap
trap 'handle_error $LINENO' ERR

# Function to check for required commands
check_requirements() {
    log "Checking requirements..."
    
    # Check for git
    if ! command -v git > /dev/null 2>&1; then
        if command -v gum > /dev/null 2>&1; then
            gum format --theme=warm "❌ Git is required but not installed. Aborting."
        else
            log_error "Git is required but not installed. Aborting."
        fi
        exit 1
    fi
    
    # Check sudo privileges
    if ! sudo -n true 2>/dev/null; then
        if command -v gum > /dev/null 2>&1; then
            gum format --theme=warm "❌ Sudo privileges required. Please run with sudo access."
        else
            log_error "Sudo privileges required. Please run with sudo access."
        fi
        exit 1
    fi
    
    # Check for gum (install if not present)
    if ! command -v gum > /dev/null 2>&1; then
        log "Installing gum for better user experience..."
        if command -v pacman > /dev/null 2>&1; then
            sudo pacman -S --noconfirm gum
        elif command -v apt > /dev/null 2>&1; then
            sudo apt update && sudo apt install -y gum
        else
            log_warning "gum not available, using basic prompts"
        fi
    fi
    
    log_success "Requirements check passed"
}

# Function to detect OS
detect_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine operating system"
        exit 1
    fi
    
    source /etc/os-release
    log "Detected OS: $NAME $VERSION"
}

# Function to clone or update repository
update_repository() {
    log "Setting up repository..."
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$REPO_PATH")"
    
    if [ -d "$REPO_PATH" ]; then
        log "Repository exists, updating..."
        cd "$REPO_PATH"
        if ! git fetch origin; then
            log_error "Failed to fetch from origin"
            exit 1
        fi
        if ! git checkout "$DESKTOP_REF"; then
            log_error "Failed to checkout branch: $DESKTOP_REF"
            exit 1
        fi
        if ! git pull origin "$DESKTOP_REF"; then
            log_error "Failed to pull from origin"
            exit 1
        fi
        log_success "Repository updated to branch: $DESKTOP_REF"
    else
        log "Cloning repository..."
        if ! git clone --branch "$DESKTOP_REF" "$REPO_URL" "$REPO_PATH"; then
            log_error "Failed to clone repository"
            exit 1
        fi
        log_success "Repository cloned to: $REPO_PATH"
    fi
}

# Function to make scripts executable
make_scripts_executable() {
    log "Making scripts executable..."
    
    local script_path="$REPO_PATH"
    
    # Make main install script executable
    if [[ -f "$script_path/install.sh" ]]; then
        chmod +x "$script_path/install.sh"
    fi
    
    # Make scripts in bin/ executable
    if [[ -d "$script_path/bin" ]]; then
        find "$script_path/bin" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    fi
    
    # Make scripts in install/ executable
    if [[ -d "$script_path/install" ]]; then
        find "$script_path/install" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    fi
    
    log_success "Scripts made executable"
}

# Function to get user confirmation
get_user_confirmation() {
    if command -v gum > /dev/null 2>&1; then
        gum confirm "Do you want to proceed with the desktop setup?" || {
            gum format --theme=warm "Setup cancelled by user."
            exit 0
        }
    else
        echo -n "Do you want to proceed with the desktop setup? (y/N): "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                log "Proceeding with setup..."
                ;;
            *)
                log "Setup cancelled by user."
                exit 0
                ;;
        esac
    fi
}

# Function to call install.sh
call_installer() {
    log "Calling install.sh..."
    
    local install_script="$REPO_PATH/install.sh"
    
    if [[ -f "$install_script" ]]; then
        chmod +x "$install_script"
        cd "$REPO_PATH"
        "$install_script" "$@"
    else
        if command -v gum > /dev/null 2>&1; then
            gum format --theme=warm "❌ install.sh not found in repository"
        else
            log_error "install.sh not found in repository"
        fi
        exit 1
    fi
}

# Main function
main() {
    show_banner
    detect_os
    check_requirements
    
    # Get user confirmation
    get_user_confirmation
    
    # Update repository if we're not already running from the target location
    if [[ "$SCRIPT_DIR" != "$REPO_PATH" ]]; then
        update_repository
    else
        log "Already running from target location, skipping repository update"
    fi
    
    # Make scripts executable
    make_scripts_executable
    
    # Call installer with any arguments passed to bootstrap
    call_installer "$@"
    
    if command -v gum > /dev/null 2>&1; then
        gum format --theme=warm "🎉 Bootstrap completed successfully!"
    else
        log_success "Bootstrap completed successfully!"
    fi
}

# Run main function with all arguments
main "$@"
