#!/bin/bash

# System Configuration and Themes Installation Script
# This script applies system-wide configurations and themes for KDE Plasma

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if gum is available
if ! command -v gum &> /dev/null; then
    print_error "gum is not installed. Please install it first."
    exit 1
fi

print_status "Starting system configuration and themes installation..."

# Get script directory and config directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
USER_CONFIG_DIR="$HOME/.config"

# Function to copy configuration files
copy_config_files() {
    print_status "Copying configuration files from $CONFIG_DIR to $USER_CONFIG_DIR..."
    
    if [[ ! -d "$CONFIG_DIR" ]]; then
        print_warning "Config directory $CONFIG_DIR does not exist. Creating it..."
        mkdir -p "$CONFIG_DIR"
        return 0
    fi
    
    # Create ~/.config if it doesn't exist
    mkdir -p "$USER_CONFIG_DIR"
    
    # Copy all configuration files and directories
    for item in "$CONFIG_DIR"/*; do
        if [[ -e "$item" ]]; then
            item_name=$(basename "$item")
            
            # Skip README files and scripts
            if [[ "$item_name" == "README"* ]] || [[ "$item_name" == "*.sh" ]]; then
                continue
            fi
            
            if [[ -d "$item" ]]; then
                print_status "Copying directory: $item_name"
                cp -r "$item" "$USER_CONFIG_DIR/"
            elif [[ -f "$item" ]]; then
                print_status "Copying file: $item_name"
                cp "$item" "$USER_CONFIG_DIR/"
            fi
        fi
    done
    
    print_success "Configuration files copied successfully"
}

# Function to install GTK themes
install_gtk_themes() {
    print_status "Installing GTK themes and icons..."
    
    # Popular GTK themes and icon packages
    local gtk_packages=(
        "gtk-theme-arc-gtk"
        "gtk-theme-numix"
        "papirus-icon-theme"
        "breeze-gtk"
        "breeze-icons"
        "adwaita-icon-theme"
        "hicolor-icon-theme"
        "oxygen-icons"
        "noto-fonts"
        "noto-fonts-emoji"
        "ttf-liberation"
        "ttf-dejavu"
    )
    
    for package in "${gtk_packages[@]}"; do
        if pacman -Qi "$package" &> /dev/null; then
            print_status "$package is already installed"
        else
            if gum confirm "Install $package?"; then
                print_status "Installing $package..."
                if yay -S --needed --noconfirm "$package"; then
                    print_success "$package installed successfully"
                else
                    print_warning "Failed to install $package, continuing..."
                fi
            fi
        fi
    done
}

# Function to install QT themes
install_qt_themes() {
    print_status "Installing QT themes..."
    
    # QT theme packages
    local qt_packages=(
        "qt5ct"
        "qt6ct"
        "kvantum"
        "kvantum-theme-arc"
        "kvantum-theme-materia"
        "breeze"
        "oxygen"
    )
    
    for package in "${qt_packages[@]}"; do
        if pacman -Qi "$package" &> /dev/null; then
            print_status "$package is already installed"
        else
            if gum confirm "Install $package?"; then
                print_status "Installing $package..."
                if yay -S --needed --noconfirm "$package"; then
                    print_success "$package installed successfully"
                else
                    print_warning "Failed to install $package, continuing..."
                fi
            fi
        fi
    done
}

# Function to configure Plymouth boot splash
configure_plymouth() {
    print_status "Configuring Plymouth boot splash..."
    
    if ! command -v plymouth &> /dev/null; then
        if gum confirm "Plymouth not found. Install Plymouth boot splash?"; then
            print_status "Installing Plymouth..."
            if yay -S --needed --noconfirm plymouth; then
                print_success "Plymouth installed successfully"
            else
                print_error "Failed to install Plymouth"
                return 1
            fi
        else
            print_status "Skipping Plymouth configuration"
            return 0
        fi
    fi
    
    # Install Plymouth themes
    local plymouth_themes=(
        "plymouth-theme-breeze"
        "plymouth-theme-spinner"
    )
    
    for theme in "${plymouth_themes[@]}"; do
        if gum confirm "Install $theme?"; then
            print_status "Installing $theme..."
            if yay -S --needed --noconfirm "$theme"; then
                print_success "$theme installed successfully"
            else
                print_warning "Failed to install $theme, continuing..."
            fi
        fi
    done
    
    # Configure Plymouth
    if gum confirm "Configure Plymouth with breeze theme?"; then
        print_status "Setting Plymouth theme to breeze..."
        sudo plymouth-set-default-theme -R breeze
        print_success "Plymouth theme configured"
        
        # Update initramfs
        print_status "Updating initramfs..."
        sudo mkinitcpio -P
        print_success "Initramfs updated"
    fi
}

# Function to configure Swaylock (if using Wayland)
configure_swaylock() {
    print_status "Configuring Swaylock screen locker..."
    
    if ! command -v swaylock &> /dev/null; then
        if gum confirm "Swaylock not found. Install Swaylock screen locker?"; then
            print_status "Installing Swaylock..."
            if yay -S --needed --noconfirm swaylock-effects; then
                print_success "Swaylock installed successfully"
            else
                print_error "Failed to install Swaylock"
                return 1
            fi
        else
            print_status "Skipping Swaylock configuration"
            return 0
        fi
    fi
    
    # Create swaylock config
    mkdir -p "$USER_CONFIG_DIR/swaylock"
    
    cat > "$USER_CONFIG_DIR/swaylock/config" << 'EOF'
# Swaylock configuration
daemonize
show-failed-attempts
clock
screenshot
effect-blur=7x5
effect-vignette=0.5:0.5
color=1f1f1f
font=sans-serif
indicator
indicator-radius=200
indicator-thickness=20
line-color=ffffff
ring-color=231f20
inside-color=231f20
key-hl-color=d23c3d
separator-color=00000000
text-color=ffffff
text-caps-lock-color=""
line-ver-color=d23c3d
ring-ver-color=d23c3d
inside-ver-color=d23c3d
text-ver-color=000000
ring-wrong-color=d23c3d
text-wrong-color=d23c3d
inside-wrong-color=d23c3d
inside-clear-color=d23c3d
text-clear-color=000000
ring-clear-color=d23c3d
line-clear-color=000000
line-wrong-color=000000
bs-hl-color=d23c3d
grace=2
grace-no-mouse
grace-no-touch
datestr="%a, %B %e"
timestr="%I:%M %p"
fade-in=0.2
ignore-empty-password
EOF
    
    print_success "Swaylock configuration created"
}

# Function to configure KDE Plasma themes
configure_kde_themes() {
    print_status "Configuring KDE Plasma themes..."
    
    # Install additional KDE themes
    local kde_themes=(
        "plasma-theme-breath"
        "latte-dock"
        "kde-gtk-config"
        "breeze-gtk"
        "plasma5-applets-window-buttons"
        "plasma5-applets-window-title"
    )
    
    for theme in "${kde_themes[@]}"; do
        if gum confirm "Install $theme?"; then
            print_status "Installing $theme..."
            if yay -S --needed --noconfirm "$theme"; then
                print_success "$theme installed successfully"
            else
                print_warning "Failed to install $theme, continuing..."
            fi
        fi
    done
    
    # Configure KDE settings
    print_status "Applying KDE theme settings..."
    
    # Set dark theme
    if gum confirm "Apply dark theme to KDE?"; then
        kwriteconfig5 --file kdeglobals --group General --key ColorScheme "BreezeDark"
        kwriteconfig5 --file kdeglobals --group KDE --key widgetStyle "Breeze"
        kwriteconfig5 --file kdeglobals --group Icons --key Theme "breeze-dark"
        kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "Breeze"
        print_success "Dark theme applied"
    fi
    
    # Configure window decorations
    if gum confirm "Configure window decorations?"; then
        kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key BorderSize "Normal"
        kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto "false"
        kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "MS"
        kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
        print_success "Window decorations configured"
    fi
}

# Function to configure ZSH and Powerlevel10k
configure_zsh_p10k() {
    print_status "Configuring ZSH shell and Powerlevel10k theme..."
    
    # Install ZSH if not already installed
    if ! command -v zsh &> /dev/null; then
        print_status "Installing ZSH..."
        sudo pacman -S --needed --noconfirm zsh
    fi
    
    # Install Oh My Zsh if not already installed
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_status "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Install Powerlevel10k theme
    if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
        print_status "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    fi
    
    # Install ZSH plugins
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        print_status "Installing zsh-autosuggestions plugin..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
    fi
    
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        print_status "Installing zsh-syntax-highlighting plugin..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
    fi
    
    # Apply ZSH configuration
    if [[ -f "$SCRIPT_DIR/config/zshrc" ]]; then
        print_status "Applying ZSH configuration..."
        cp "$SCRIPT_DIR/config/zshrc" "$HOME/.zshrc"
        print_success "ZSH configuration applied"
    fi
    
    # Apply Powerlevel10k configuration
    if [[ -f "$SCRIPT_DIR/config/p10k.zsh" ]]; then
        print_status "Applying Powerlevel10k configuration..."
        cp "$SCRIPT_DIR/config/p10k.zsh" "$HOME/.p10k.zsh"
        print_success "Powerlevel10k configuration applied"
    fi
    
    # Change default shell to ZSH
    if [[ "$SHELL" != *"zsh"* ]]; then
        print_status "Changing default shell to ZSH..."
        chsh -s $(which zsh)
        print_success "Default shell changed to ZSH (will take effect on next login)"
    fi
    
    # Apply KDE Plasma configuration
    if [[ -f "$SCRIPT_DIR/config/kde/plasma-desktop-appletsrc" ]]; then
        print_status "Applying KDE Plasma desktop applets configuration..."
        cp "$SCRIPT_DIR/config/kde/plasma-desktop-appletsrc" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
        print_success "KDE Plasma applets configuration applied"
    fi
    
    if [[ -f "$SCRIPT_DIR/config/kde/plasmashellrc" ]]; then
        print_status "Applying KDE Plasma shell configuration..."
        cp "$SCRIPT_DIR/config/kde/plasmashellrc" "$HOME/.config/plasmashellrc"
        print_success "KDE Plasma shell configuration applied"
    fi
    
    print_success "ZSH and Powerlevel10k configuration completed"
}

# Function to reload desktop environment settings
reload_desktop_settings() {
    print_status "Reloading desktop environment settings..."
    
    # Detect desktop environment
    if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || [[ "$DESKTOP_SESSION" == *"plasma"* ]]; then
        print_status "Detected KDE Plasma desktop"
        
        # Reload KDE settings
        if command -v kbuildsycoca5 &> /dev/null; then
            print_status "Rebuilding KDE system configuration cache..."
            kbuildsycoca5 --noincremental
        fi
        
        if command -v kquitapp5 &> /dev/null && command -v kstart5 &> /dev/null; then
            print_status "Restarting Plasma shell..."
            kquitapp5 plasmashell && kstart5 plasmashell
        fi
        
        # Reload KWin if running
        if command -v kwin_x11 &> /dev/null || command -v kwin_wayland &> /dev/null; then
            print_status "Reloading KWin..."
            qdbus org.kde.KWin /KWin reconfigure
        fi
        
    elif [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        print_status "Detected GNOME desktop"
        
        # Reload GNOME settings
        if command -v gsettings &> /dev/null; then
            print_status "Reloading GNOME settings..."
            gsettings reset-recursively org.gnome.desktop.interface
        fi
        
    else
        print_warning "Desktop environment not detected or not supported for automatic reload"
        print_status "You may need to log out and log back in to see all changes"
    fi
    
    # Update font cache
    if command -v fc-cache &> /dev/null; then
        print_status "Updating font cache..."
        fc-cache -fv
    fi
    
    # Update icon cache
    if command -v gtk-update-icon-cache &> /dev/null; then
        print_status "Updating icon cache..."
        gtk-update-icon-cache -f -t /usr/share/icons/hicolor/ 2>/dev/null || true
        gtk-update-icon-cache -f -t "$HOME/.local/share/icons/" 2>/dev/null || true
    fi
    
    print_success "Desktop environment settings reloaded"
}

# Main execution
echo "=== System Configuration and Themes Installation ==="
echo

# Copy configuration files
if gum confirm "Copy configuration files from config/ to ~/.config/?"; then
    copy_config_files
fi

# Install GTK themes
if gum confirm "Install GTK themes and icons?"; then
    install_gtk_themes
fi

# Install QT themes
if gum confirm "Install QT themes?"; then
    install_qt_themes
fi

# Configure KDE themes
if gum confirm "Configure KDE Plasma themes?"; then
    configure_kde_themes
fi

# Configure Plymouth
if gum confirm "Configure Plymouth boot splash?"; then
    configure_plymouth
fi

# Configure Swaylock
if gum confirm "Configure Swaylock screen locker?"; then
    configure_swaylock
fi

# Configure ZSH and Powerlevel10k
if gum confirm "Configure ZSH shell and Powerlevel10k theme?"; then
    configure_zsh_p10k
fi

# Reload desktop settings
if gum confirm "Reload desktop environment settings?"; then
    reload_desktop_settings
fi

print_success "System configuration and themes installation completed!"
print_status "You may need to log out and log back in to see all changes take effect."

# Create a summary of what was configured
echo
echo "=== Configuration Summary ==="
echo "✓ Configuration files copied to ~/.config/"
echo "✓ GTK/QT themes and icons installed"
echo "✓ KDE Plasma themes configured"
echo "✓ KDE Plasma desktop applets and plasmoids configured"
echo "✓ ZSH shell with Powerlevel10k theme configured"
echo "✓ Plymouth boot splash configured (if selected)"
echo "✓ Swaylock screen locker configured (if selected)"
echo "✓ Desktop environment settings reloaded"
echo
print_status "Configuration complete!"
print_status "Note: You may need to log out and log back in to see all changes take effect."
