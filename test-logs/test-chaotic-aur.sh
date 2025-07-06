#!/bin/bash
set -euo pipefail

echo "=== Testing Chaotic AUR Setup ==="
echo "Container started at: $(date)"

# Update system
echo "Updating system..."
pacman -Syu --noconfirm

# Install basic requirements
echo "Installing basic requirements..."
pacman -S --noconfirm base-devel git curl wget sudo jq

# Import Chaotic AUR keys
echo "Importing Chaotic AUR keys..."
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB

# Install chaotic-keyring and chaotic-mirrorlist
echo "Installing chaotic-keyring and chaotic-mirrorlist..."
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.xz' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.xz'

# Add Chaotic AUR to pacman.conf
echo "Adding Chaotic AUR to pacman.conf..."
echo "" >> /etc/pacman.conf
echo "[chaotic-aur]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf

# Update package database
echo "Updating package database..."
pacman -Sy

# Verify Chaotic AUR is working
echo "Verifying Chaotic AUR setup..."
if pacman -Sl chaotic-aur > /dev/null 2>&1; then
    echo "✓ Chaotic AUR is working correctly"
    echo "Available packages: $(pacman -Sl chaotic-aur | wc -l)"
else
    echo "✗ Chaotic AUR setup failed"
    exit 1
fi

echo "=== Chaotic AUR Test Completed ==="
echo "Container finished at: $(date)"
