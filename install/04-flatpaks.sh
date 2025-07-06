#!/bin/bash

# install/04-flatpaks.sh - Install Flatpak runtime and applications
# This script installs Flatpak, adds Flathub remote, and installs specified applications

set -e

echo "=== Installing Flatpak Runtime and Applications ==="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running on Arch Linux
is_arch_linux() {
    [ -f /etc/arch-release ] || command_exists pacman
}

# Ensure flatpak is installed
echo "Checking if Flatpak is installed..."
if ! command_exists flatpak; then
    echo "Flatpak not found. Installing Flatpak..."
    
    if is_arch_linux; then
        # Install on Arch Linux
        sudo pacman -S --needed --noconfirm flatpak
    elif command_exists apt; then
        # Install on Debian/Ubuntu
        sudo apt update
        sudo apt install -y flatpak
    elif command_exists dnf; then
        # Install on Fedora
        sudo dnf install -y flatpak
    elif command_exists zypper; then
        # Install on openSUSE
        sudo zypper install -y flatpak
    else
        echo "Error: Unable to determine package manager. Please install Flatpak manually."
        exit 1
    fi
    
    echo "Flatpak installed successfully."
else
    echo "Flatpak is already installed."
fi

# Add Flathub remote
echo "Adding Flathub remote..."
if flatpak remote-list | grep -q "flathub"; then
    echo "Flathub remote already exists."
else
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "Flathub remote added successfully."
fi

# Install specified applications
echo "Installing Flatpak applications..."
APPS=(
    "com.obsproject.Studio"           # OBS Studio
    "com.spotify.Client"              # Spotify
    "com.usebottles.bottles"          # Bottles
    "io.github.flattool.Warehouse"    # Warehouse (Flatpak manager, alternative to EasyFlatpak)
)

for app in "${APPS[@]}"; do
    echo "Installing $app..."
    if flatpak list | grep -q "$app"; then
        echo "$app is already installed."
    else
        flatpak install -y flathub "$app"
        echo "$app installed successfully."
    fi
done

# Note about EasyFlatpak
echo ""
echo "Note: EasyFlatpak (org.easy_flatpak.EasyFlatpak) appears to be unavailable on Flathub."
echo "Installed Warehouse (io.github.flattool.Warehouse) as an alternative Flatpak manager."
echo "You can also try installing EasyFlatpak from other sources if needed."

# Create config directory for Flatpak overrides
CONFIG_DIR="$HOME/.config/flatpak"
echo ""
echo "Creating Flatpak configuration directory..."
mkdir -p "$CONFIG_DIR"

# Create a sample override configuration
cat > "$CONFIG_DIR/README.md" << 'EOF'
# Flatpak Overrides Configuration

This directory can contain Flatpak application overrides to customize permissions and settings.

## Examples:

### Allow a Flatpak app to access additional directories:
```bash
flatpak override --user --filesystem=/path/to/directory com.example.App
```

### Remove network access from an app:
```bash
flatpak override --user --unshare=network com.example.App
```

### Allow an app to access the host system:
```bash
flatpak override --user --filesystem=host com.example.App
```

### View current overrides:
```bash
flatpak override --user --show
```

### Reset overrides for an app:
```bash
flatpak override --user --reset com.example.App
```

## Common overrides for installed apps:

### OBS Studio - Allow access to additional directories for recordings:
```bash
flatpak override --user --filesystem=home com.obsproject.Studio
```

### Bottles - Allow access to Windows applications and games:
```bash
flatpak override --user --filesystem=home com.usebottles.bottles
```

For more information, see: https://docs.flatpak.org/en/latest/sandbox-permissions.html
EOF

echo "Created Flatpak configuration directory at $CONFIG_DIR"
echo "See $CONFIG_DIR/README.md for override configuration examples."

echo ""
echo "=== Flatpak Installation Complete ==="
echo "Installed applications:"
echo "  - OBS Studio (com.obsproject.Studio)"
echo "  - Spotify (com.spotify.Client)"
echo "  - Bottles (com.usebottles.bottles)"
echo "  - Warehouse (io.github.flattool.Warehouse)"
echo ""
echo "You may need to log out and log back in for Flatpak applications to appear in your application menu."
