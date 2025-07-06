#!/bin/bash

# OBS Studio Flatpak Overrides
# This script applies useful overrides for OBS Studio

echo "Applying OBS Studio Flatpak overrides..."

# Allow access to home directory for recordings and configurations
flatpak override --user --filesystem=home com.obsproject.Studio

# Allow access to additional hardware devices
flatpak override --user --device=all com.obsproject.Studio

# Enable PulseAudio for audio capture
flatpak override --user --socket=pulseaudio com.obsproject.Studio

# Allow access to webcam and other video devices
flatpak override --user --device=dri com.obsproject.Studio

# Enable desktop integration
flatpak override --user --talk-name=org.freedesktop.Notifications com.obsproject.Studio

echo "OBS Studio overrides applied successfully."
echo "Note: You may need to restart OBS Studio for changes to take effect."
