#!/bin/bash
# backup-config.sh - Backup important configuration files
# Usage: ./backup-config.sh [backup-directory]

set -e

# Configuration
BACKUP_DIR="${1:-$HOME/backups/config-$(date +%Y%m%d_%H%M%S)}"
HOSTNAME=$(hostname)

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
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[BACKUP]${NC} $1"
}

# Create backup directory
print_status "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Function to backup file/directory if it exists
backup_if_exists() {
    local source="$1"
    local dest_name="$2"
    
    if [ -e "$source" ]; then
        print_status "Backing up $source"
        cp -r "$source" "$BACKUP_DIR/$dest_name" 2>/dev/null || {
            print_warning "Failed to backup $source"
            return 1
        }
    else
        print_warning "$source does not exist, skipping"
    fi
}

# System information
print_header "Creating system information file"
{
    echo "Backup created: $(date)"
    echo "Hostname: $HOSTNAME"
    echo "User: $USER"
    echo "Kernel: $(uname -r)"
    echo "Distribution: $(lsb_release -d -s 2>/dev/null || echo 'Unknown')"
    echo "Architecture: $(uname -m)"
    echo "Tailscale Status: $(tailscale status --self=false 2>/dev/null | head -1 || echo 'Not available')"
} > "$BACKUP_DIR/system-info.txt"

# Backup shell configurations
print_header "Backing up shell configurations"
backup_if_exists "$HOME/.bashrc" "bashrc"
backup_if_exists "$HOME/.zshrc" "zshrc"
backup_if_exists "$HOME/.bash_profile" "bash_profile"
backup_if_exists "$HOME/.profile" "profile"
backup_if_exists "$HOME/.inputrc" "inputrc"
backup_if_exists "$HOME/.bash_aliases" "bash_aliases"

# Backup SSH configurations
print_header "Backing up SSH configurations"
backup_if_exists "$HOME/.ssh/config" "ssh_config"
backup_if_exists "$HOME/.ssh/known_hosts" "ssh_known_hosts"

# Backup Git configuration
print_header "Backing up Git configuration"
backup_if_exists "$HOME/.gitconfig" "gitconfig"
backup_if_exists "$HOME/.gitignore_global" "gitignore_global"

# Backup KDE configurations
print_header "Backing up KDE configurations"
backup_if_exists "$HOME/.config/kdeglobals" "kde_kdeglobals"
backup_if_exists "$HOME/.config/kwinrc" "kde_kwinrc"
backup_if_exists "$HOME/.config/plasmarc" "kde_plasmarc"
backup_if_exists "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "kde_desktop_applets"
backup_if_exists "$HOME/.config/kscreenlockerrc" "kde_screenlocker"
backup_if_exists "$HOME/.config/konsolerc" "kde_konsole"
backup_if_exists "$HOME/.config/katerc" "kde_kate"

# Backup application configurations
print_header "Backing up application configurations"
backup_if_exists "$HOME/.config/Code/User/settings.json" "vscode_settings.json"
backup_if_exists "$HOME/.config/Code/User/keybindings.json" "vscode_keybindings.json"
backup_if_exists "$HOME/.mozilla/firefox" "firefox_profiles"
backup_if_exists "$HOME/.thunderbird" "thunderbird_profiles"

# Backup Docker configurations
print_header "Backing up Docker configurations"
backup_if_exists "$HOME/.docker/config.json" "docker_config.json"
backup_if_exists "/etc/docker/daemon.json" "docker_daemon.json"

# Backup systemd user services
print_header "Backing up systemd user services"
backup_if_exists "$HOME/.config/systemd/user" "systemd_user_services"

# Backup Flatpak overrides
print_header "Backing up Flatpak overrides"
backup_if_exists "$HOME/.local/share/flatpak/overrides" "flatpak_overrides"

# Backup package lists
print_header "Creating package lists"
if command -v pacman &> /dev/null; then
    print_status "Creating Arch package list"
    pacman -Qqe > "$BACKUP_DIR/pacman-packages.txt" 2>/dev/null || print_warning "Failed to create pacman package list"
    pacman -Qqem > "$BACKUP_DIR/aur-packages.txt" 2>/dev/null || print_warning "Failed to create AUR package list"
fi

if command -v flatpak &> /dev/null; then
    print_status "Creating Flatpak application list"
    flatpak list --app --columns=application > "$BACKUP_DIR/flatpak-apps.txt" 2>/dev/null || print_warning "Failed to create Flatpak list"
fi

# Backup crontab
print_header "Backing up crontab"
crontab -l > "$BACKUP_DIR/crontab.txt" 2>/dev/null || print_warning "No crontab found"

# Create archive
print_header "Creating compressed archive"
ARCHIVE_NAME="config-backup-$HOSTNAME-$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$BACKUP_DIR/../$ARCHIVE_NAME" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"

print_status "Backup completed successfully!"
print_status "Backup directory: $BACKUP_DIR"
print_status "Archive created: $(dirname "$BACKUP_DIR")/$ARCHIVE_NAME"
print_status "Total size: $(du -sh "$BACKUP_DIR" | cut -f1)"

# Optional: Clean up directory if archive was created successfully
if [ -f "$(dirname "$BACKUP_DIR")/$ARCHIVE_NAME" ]; then
    read -p "Remove backup directory and keep only archive? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$BACKUP_DIR"
        print_status "Backup directory removed, archive retained"
    fi
fi
