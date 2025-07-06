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

# Function to install Oh My Zsh
install_oh_my_zsh() {
    print_status "Checking if Oh My Zsh is installed..."
    
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        if gum confirm "Oh My Zsh not found. Install Oh My Zsh?"; then
            print_status "Installing Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || {
                print_error "Failed to install Oh My Zsh"
                return 1
            }
            print_status "Oh My Zsh installed successfully"
        else
            print_warning "Skipping Oh My Zsh installation. ZSH configuration may not work properly."
            return 1
        fi
    else
        print_status "Oh My Zsh is already installed"
    fi
}

# Function to install Powerlevel10k theme
install_powerlevel10k() {
    print_status "Checking if Powerlevel10k is installed..."
    
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [[ ! -d "$p10k_dir" ]]; then
        if gum confirm "Powerlevel10k theme not found. Install Powerlevel10k?"; then
            print_status "Installing Powerlevel10k theme..."
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" || {
                print_error "Failed to install Powerlevel10k"
                return 1
            }
            print_status "Powerlevel10k installed successfully"
        else
            print_warning "Skipping Powerlevel10k installation. ZSH theme may not work properly."
            return 1
        fi
    else
        print_status "Powerlevel10k is already installed"
    fi
}

# Function to install ZSH plugins
install_zsh_plugins() {
    print_status "Installing ZSH plugins..."
    
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    
    # Install zsh-autosuggestions
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        print_status "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions" || {
            print_error "Failed to install zsh-autosuggestions"
            return 1
        }
    else
        print_status "zsh-autosuggestions is already installed"
    fi
    
    # Install zsh-syntax-highlighting
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        print_status "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting" || {
            print_error "Failed to install zsh-syntax-highlighting"
            return 1
        }
    else
        print_status "zsh-syntax-highlighting is already installed"
    fi
}

# Function to copy configuration files
copy_zsh_configs() {
    print_status "Copying ZSH configuration files..."
    
    # Copy .zshrc
    if [[ -f "$CONFIG_DIR/zshrc" ]]; then
        if gum confirm "Copy .zshrc configuration file to home directory?"; then
            backup_file "$HOME/.zshrc"
            cp "$CONFIG_DIR/zshrc" "$HOME/.zshrc" || {
                print_error "Failed to copy .zshrc"
                return 1
            }
            print_status ".zshrc copied successfully"
        else
            print_warning "Skipping .zshrc copy"
        fi
    else
        print_error "Source .zshrc file not found at $CONFIG_DIR/zshrc"
        return 1
    fi
    
    # Copy .p10k.zsh
    if [[ -f "$CONFIG_DIR/p10k/p10k.zsh" ]]; then
        if gum confirm "Copy .p10k.zsh configuration file to home directory?"; then
            backup_file "$HOME/.p10k.zsh"
            cp "$CONFIG_DIR/p10k/p10k.zsh" "$HOME/.p10k.zsh" || {
                print_error "Failed to copy .p10k.zsh"
                return 1
            }
            print_status ".p10k.zsh copied successfully"
        else
            print_warning "Skipping .p10k.zsh copy"
        fi
    else
        print_error "Source .p10k.zsh file not found at $CONFIG_DIR/p10k/p10k.zsh"
        return 1
    fi
}

# Function to set ZSH as default shell
set_zsh_default() {
    print_status "Checking current shell..."
    
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        if gum confirm "Set ZSH as your default shell?"; then
            print_status "Setting ZSH as default shell..."
            chsh -s "$(which zsh)" || {
                print_error "Failed to set ZSH as default shell"
                return 1
            }
            print_status "ZSH set as default shell successfully"
            print_warning "You may need to log out and log back in for the change to take effect"
        else
            print_warning "Skipping setting ZSH as default shell"
        fi
    else
        print_status "ZSH is already the default shell"
    fi
}

# Function to install ZSH if not present
install_zsh() {
    print_status "Checking if ZSH is installed..."
    
    if ! command -v zsh &> /dev/null; then
        if gum confirm "ZSH not found. Install ZSH using $AUR_HELPER?"; then
            print_status "Installing ZSH..."
            sudo pacman -S --needed --noconfirm zsh || {
                print_error "Failed to install ZSH"
                return 1
            }
            print_status "ZSH installed successfully"
        else
            print_error "ZSH is required for this configuration"
            return 1
        fi
    else
        print_status "ZSH is already installed"
    fi
}

# Main installation process
print_section "=== ZSH Configuration Setup ==="
echo

# Check if gum is available
if ! command -v gum &> /dev/null; then
    print_error "gum is required but not installed. Please install gum first."
    exit 1
fi

# Install ZSH if needed
if ! install_zsh; then
    print_error "Failed to install ZSH"
    exit 1
fi

# Install Oh My Zsh
if ! install_oh_my_zsh; then
    print_error "Oh My Zsh installation failed"
    exit 1
fi

# Install Powerlevel10k theme
if ! install_powerlevel10k; then
    print_error "Powerlevel10k installation failed"
    exit 1
fi

# Install ZSH plugins
if ! install_zsh_plugins; then
    print_error "ZSH plugins installation failed"
    exit 1
fi

# Copy configuration files
if ! copy_zsh_configs; then
    print_error "Failed to copy ZSH configuration files"
    exit 1
fi

# Set ZSH as default shell
set_zsh_default

print_section "ZSH configuration setup completed successfully!"
print_status "Your ZSH environment is now configured with:"
print_status "  - Oh My Zsh framework"
print_status "  - Powerlevel10k theme"
print_status "  - Custom .zshrc configuration"
print_status "  - Custom .p10k.zsh Powerlevel10k configuration"
print_status "  - zsh-autosuggestions plugin"
print_status "  - zsh-syntax-highlighting plugin"
echo
print_warning "If ZSH was set as your default shell, please log out and log back in to apply the changes."
print_warning "You may want to run 'source ~/.zshrc' to reload your shell configuration."
