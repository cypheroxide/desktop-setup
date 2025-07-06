#!/bin/bash
set -euo pipefail

echo "=== Testing yay AUR Helper Flow ==="
echo "Container started at: $(date)"

# Update system
echo "Updating system..."
pacman -Syu --noconfirm

# Install basic requirements
echo "Installing basic requirements..."
pacman -S --noconfirm base-devel git curl wget sudo jq

# Create test user
echo "Creating test user..."
useradd -m -s /bin/bash testuser
echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user for AUR operations
echo "Switching to test user for AUR operations..."
sudo -u testuser bash << 'USER_SCRIPT'
set -euo pipefail
cd /home/testuser

echo "Installing yay..."
if [[ "yay" == "yay" ]]; then
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
elif [[ "yay" == "paru" ]]; then
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin
    makepkg -si --noconfirm
fi

echo "Verifying yay installation..."
if command -v yay > /dev/null; then
    echo "✓ yay installed successfully"
    yay --version
else
    echo "✗ yay installation failed"
    exit 1
fi

echo "Testing yay functionality..."
yay -Ss neofetch | head -5

echo "✓ yay test completed successfully"
USER_SCRIPT

echo "=== yay Test Completed ==="
echo "Container finished at: $(date)"
