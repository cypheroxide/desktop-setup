#!/bin/bash
# toggle-tailscale.sh - Toggle Tailscale VPN on/off
# Usage: ./toggle-tailscale.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    print_error "Tailscale is not installed. Please install it first."
    exit 1
fi

# Check current Tailscale status
print_status "Checking Tailscale status..."
STATUS=$(tailscale status --json | jq -r '.BackendState' 2>/dev/null || echo "unknown")

case $STATUS in
    "Running")
        print_status "Tailscale is currently running. Stopping..."
        sudo tailscale down
        if [ $? -eq 0 ]; then
            print_status "Tailscale stopped successfully."
        else
            print_error "Failed to stop Tailscale."
            exit 1
        fi
        ;;
    "Stopped"|"NeedsLogin"|"unknown")
        print_status "Tailscale is currently stopped. Starting..."
        sudo tailscale up
        if [ $? -eq 0 ]; then
            print_status "Tailscale started successfully."
            print_status "Current Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'Not available')"
        else
            print_error "Failed to start Tailscale."
            exit 1
        fi
        ;;
    *)
        print_warning "Tailscale is in an unknown state: $STATUS"
        print_status "Attempting to restart..."
        sudo tailscale down && sudo tailscale up
        ;;
esac

# Show final status
print_status "Final Tailscale status:"
tailscale status --self=false 2>/dev/null || print_warning "Could not retrieve status"
