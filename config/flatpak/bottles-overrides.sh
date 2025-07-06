#!/bin/bash

# Bottles Flatpak Overrides
# This script applies useful overrides for Bottles (Windows compatibility layer)

echo "Applying Bottles Flatpak overrides..."

# Allow access to home directory for Windows applications and games
flatpak override --user --filesystem=home com.usebottles.bottles

# Allow access to additional hardware devices for gaming
flatpak override --user --device=all com.usebottles.bottles

# Enable audio support
flatpak override --user --socket=pulseaudio com.usebottles.bottles

# Allow access to graphics hardware
flatpak override --user --device=dri com.usebottles.bottles

# Enable desktop integration
flatpak override --user --talk-name=org.freedesktop.Notifications com.usebottles.bottles

# Allow access to gamepad/controller devices
flatpak override --user --device=input com.usebottles.bottles

echo "Bottles overrides applied successfully."
echo "Note: You may need to restart Bottles for changes to take effect."
