#!/bin/bash

# Test script for AUR helper integration
# Tests the combined select_aur_helper and install_aur_helper functionality

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"

# Test the integrated functions
echo "Testing AUR helper integration..."

# Test 1: Command line argument parsing
echo "Testing command line argument parsing..."
if "$SCRIPT_DIR/install.sh" --help > /dev/null 2>&1; then
    log_success "Help command works correctly"
else
    log_error "Help command failed"
fi

# Test 2: Dry run with specific AUR helper
echo "Testing dry run with specific AUR helper..."
if "$SCRIPT_DIR/install.sh" --aur-helper paru --dry-run > /tmp/test_output.log 2>&1; then
    if grep -q "paru" /tmp/test_output.log; then
        log_success "Dry run with paru works correctly"
    else
        log_error "Dry run with paru didn't select paru"
    fi
else
    log_error "Dry run with paru failed"
fi

# Test 3: Verify all three AUR helpers are supported
echo "Testing all supported AUR helpers..."
for helper in yay paru trizen; do
    if "$SCRIPT_DIR/install.sh" --aur-helper "$helper" --dry-run > /tmp/test_"$helper".log 2>&1; then
        if grep -q "$helper" /tmp/test_"$helper".log; then
            log_success "Dry run with $helper works correctly"
        else
            log_error "Dry run with $helper didn't select $helper"
        fi
    else
        log_error "Dry run with $helper failed"
    fi
done

# Test 4: Check that functions are defined
echo "Testing function definitions..."
if grep -q "select_aur_helper()" "$SCRIPT_DIR/install.sh"; then
    log_success "select_aur_helper function is defined"
else
    log_error "select_aur_helper function is missing"
fi

if grep -q "install_aur_helper()" "$SCRIPT_DIR/install.sh"; then
    log_success "install_aur_helper function is defined"
else
    log_error "install_aur_helper function is missing"
fi

# Test 5: Check that trizen installation is supported
echo "Testing trizen installation support..."
if grep -q "trizen)" "$SCRIPT_DIR/install.sh"; then
    log_success "trizen installation is supported"
else
    log_error "trizen installation is not supported"
fi

# Test 6: Check gum integration
echo "Testing gum integration..."
if grep -q "gum choose" "$SCRIPT_DIR/install.sh"; then
    log_success "gum integration is present"
else
    log_error "gum integration is missing"
fi

# Clean up test files
rm -f /tmp/test_*.log

log_success "AUR helper integration test completed"
