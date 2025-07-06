#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

# Use AUR_HELPER environment variable, fallback to yay
AUR_HELPER=${AUR_HELPER:-yay}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"

# Function to backup existing files
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup_file="${file}.backup-$(date +%Y%m%d_%H%M%S)"
        print_status "Backing up existing $file to $backup_file"
        cp "$file" "$backup_file" || {
            print_error "Failed to backup $file"
            return 1
        }
    fi
}

# Function to install Neofetch
install_neofetch() {
    print_status "Checking if Neofetch is installed..."
    
    if ! command -v neofetch &> /dev/null; then
        if gum confirm "Neofetch not found. Install Neofetch using $AUR_HELPER?"; then
            print_status "Installing Neofetch..."
            
            # Try to install from official repositories first
            if sudo pacman -S --needed --noconfirm neofetch; then
                print_status "Neofetch installed successfully from official repositories"
            else
                print_warning "Failed to install from official repositories, trying with $AUR_HELPER..."
                if "$AUR_HELPER" -S --needed --noconfirm neofetch; then
                    print_status "Neofetch installed successfully using $AUR_HELPER"
                else
                    print_error "Failed to install Neofetch"
                    return 1
                fi
            fi
        else
            print_error "Neofetch is required for this configuration"
            return 1
        fi
    else
        print_status "Neofetch is already installed"
        neofetch --version
    fi
}

# Function to create neofetch config directory
create_neofetch_config_dir() {
    local neofetch_dir="$HOME/.config/neofetch"
    
    if [[ ! -d "$neofetch_dir" ]]; then
        print_status "Creating Neofetch configuration directory..."
        mkdir -p "$neofetch_dir" || {
            print_error "Failed to create Neofetch configuration directory"
            return 1
        }
        print_status "Neofetch configuration directory created at $neofetch_dir"
    else
        print_status "Neofetch configuration directory already exists"
    fi
}

# Function to copy neofetch configuration
copy_neofetch_config() {
    print_status "Copying Neofetch configuration..."
    
    local source_config="$CONFIG_DIR/neofetch/config.conf"
    local target_config="$HOME/.config/neofetch/config.conf"
    
    if [[ -f "$source_config" ]]; then
        if gum confirm "Copy Neofetch configuration file?"; then
            # Create config directory if it doesn't exist
            create_neofetch_config_dir || return 1
            
            # Backup existing config
            backup_file "$target_config"
            
            # Copy new config
            cp "$source_config" "$target_config" || {
                print_error "Failed to copy Neofetch configuration"
                return 1
            }
            print_status "Neofetch configuration copied successfully"
            
            # Make sure the hostname is updated in the config for this system
            update_neofetch_hostname "$target_config"
        else
            print_warning "Skipping Neofetch configuration copy"
        fi
    else
        print_error "Source Neofetch configuration not found at $source_config"
        return 1
    fi
}

# Function to update hostname in neofetch config
update_neofetch_hostname() {
    local config_file="$1"
    local current_hostname=$(hostname)
    
    print_status "Updating hostname in Neofetch configuration..."
    
    # Replace ErisOS with current hostname
    if sed -i "s/ErisOS/$current_hostname/g" "$config_file"; then
        print_status "Hostname updated to $current_hostname in Neofetch configuration"
    else
        print_warning "Failed to update hostname in Neofetch configuration"
    fi
}

# Function to test neofetch installation
test_neofetch() {
    print_status "Testing Neofetch installation..."
    
    if gum confirm "Run a test of Neofetch to verify it's working?"; then
        print_status "Running Neofetch test..."
        echo
        neofetch || {
            print_error "Neofetch test failed"
            return 1
        }
        echo
        print_status "Neofetch test completed successfully"
    else
        print_warning "Skipping Neofetch test"
    fi
}

# Function to add neofetch to shell startup (optional)
add_neofetch_to_shell() {
    print_status "Checking shell startup configuration..."
    
    if gum confirm "Add Neofetch to your shell startup (.zshrc or .bashrc)?"; then
        local shell_config=""
        
        # Determine which shell config to use
        if [[ -f "$HOME/.zshrc" ]]; then
            shell_config="$HOME/.zshrc"
        elif [[ -f "$HOME/.bashrc" ]]; then
            shell_config="$HOME/.bashrc"
        else
            print_warning "No shell configuration file found (.zshrc or .bashrc)"
            return 1
        fi
        
        # Check if neofetch is already in the config
        if grep -q "neofetch" "$shell_config"; then
            print_status "Neofetch is already configured in $shell_config"
        else
            print_status "Adding Neofetch to $shell_config..."
            echo "" >> "$shell_config"
            echo "# Display system information with Neofetch" >> "$shell_config"
            echo "neofetch" >> "$shell_config"
            print_status "Neofetch added to $shell_config"
            print_warning "Restart your terminal or run 'source $shell_config' to see the changes"
        fi
    else
        print_warning "Skipping shell startup configuration"
    fi
}

# Function to install additional dependencies
install_dependencies() {
    print_status "Checking for additional dependencies..."
    
    # Check for imagemagick (for image support)
    if ! command -v convert &> /dev/null; then
        if gum confirm "ImageMagick not found. Install it for image support in Neofetch?"; then
            print_status "Installing ImageMagick..."
            sudo pacman -S --needed --noconfirm imagemagick || {
                print_warning "Failed to install ImageMagick"
            }
        fi
    else
        print_status "ImageMagick is already installed"
    fi
    
    # Check for w3m (for terminal image display)
    if ! command -v w3m &> /dev/null; then
        if gum confirm "w3m not found. Install it for terminal image display in Neofetch?"; then
            print_status "Installing w3m..."
            sudo pacman -S --needed --noconfirm w3m || {
                print_warning "Failed to install w3m"
            }
        fi
    else
        print_status "w3m is already installed"
    fi
}

# Main installation process
print_section "=== Neofetch Configuration Setup ==="
echo

# Check if gum is available
if ! command -v gum &> /dev/null; then
    print_error "gum is required but not installed. Please install gum first."
    exit 1
fi

# Install Neofetch
if ! install_neofetch; then
    print_error "Failed to install Neofetch"
    exit 1
fi

# Install additional dependencies
install_dependencies

# Copy neofetch configuration
if ! copy_neofetch_config; then
    print_error "Failed to copy Neofetch configuration"
    exit 1
fi

# Test neofetch installation
test_neofetch

# Add neofetch to shell startup (optional)
add_neofetch_to_shell

print_section "Neofetch configuration setup completed successfully!"
print_status "Your system information tool is now configured with:"
print_status "  - Neofetch system information display"
print_status "  - Custom configuration file with styled output"
print_status "  - Optional shell startup integration"
print_status "  - Optional image support dependencies"
echo
print_status "You can run 'neofetch' at any time to display system information"
print_warning "If you added Neofetch to your shell startup, restart your terminal to see it automatically"
