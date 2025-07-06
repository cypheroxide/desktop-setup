#!/bin/bash
set -euo pipefail

echo "=== Testing paru AUR Helper Flow ==="
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

echo "Installing paru..."
if [[ "paru" == "yay" ]]; then
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
elif [[ "paru" == "paru" ]]; then
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin
    makepkg -si --noconfirm
fi

echo "Verifying paru installation..."
if command -v paru > /dev/null; then
    echo "✓ paru installed successfully"
    paru --version
else
    echo "✗ paru installation failed"
    exit 1
fi

echo "Testing paru functionality..."
paru -Ss neofetch | head -5

echo "✓ paru test completed successfully"
USER_SCRIPT

echo "=== paru Test Completed ==="
echo "Container finished at: $(date)"
