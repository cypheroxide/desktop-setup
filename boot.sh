#!/bin/bash

# Desktop Setup Bootstrap Script
# This script initializes the desktop setup process

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Desktop Setup Bootstrap ==="
echo "Project directory: $SCRIPT_DIR"
echo

# Check if running on supported system
if [[ ! -f /etc/os-release ]]; then
    echo "Error: Cannot determine operating system"
    exit 1
fi

source /etc/os-release
echo "Detected OS: $NAME $VERSION"

# Make scripts executable
chmod +x "$SCRIPT_DIR/install.sh"
find "$SCRIPT_DIR/bin" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "$SCRIPT_DIR/install" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo "Bootstrap complete. Run './install.sh' to begin installation."
