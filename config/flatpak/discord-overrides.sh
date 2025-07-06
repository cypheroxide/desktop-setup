#!/bin/bash
# Discord Flatpak overrides for better functionality
# Allows access to downloads, documents, and improves audio/video functionality

echo "Applying Discord Flatpak overrides..."

# Allow filesystem access to common directories
flatpak override --user com.discordapp.Discord \
    --filesystem=xdg-download \
    --filesystem=xdg-documents \
    --filesystem=xdg-pictures \
    --filesystem=~/Downloads \
    --filesystem=~/Documents \
    --filesystem=~/Pictures

# Allow device access for better hardware support
flatpak override --user com.discordapp.Discord \
    --device=all

# Enable audio/video permissions
flatpak override --user com.discordapp.Discord \
    --socket=pulseaudio \
    --socket=wayland \
    --socket=fallback-x11

# Allow system bus access for notifications
flatpak override --user com.discordapp.Discord \
    --socket=system-bus

# Allow session bus for desktop integration
flatpak override --user com.discordapp.Discord \
    --socket=session-bus

# Environment variables for better functionality
flatpak override --user com.discordapp.Discord \
    --env=PULSE_RUNTIME_PATH=/run/user/$(id -u)/pulse

echo "Discord Flatpak overrides applied successfully!"
echo "Restart Discord for changes to take effect."
