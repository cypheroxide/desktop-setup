# AUR Helper Selection Implementation

## Overview
This document summarizes the implementation of Step 6: Add AUR Helper Selection functionality to the desktop setup installer.

## Features Implemented

### 1. Interactive AUR Helper Selection
- Added prompt: "Choose AUR helper: **yay** or **paru**"
- Supports both `gum` (if available) and fallback to basic `read` prompt
- Provides clear options with descriptions:
  - `yay` - Default, feature-rich AUR helper
  - `paru` - Rust-based AUR helper
- Automatic fallback to `yay` for invalid inputs

### 2. AUR Helper Installation
- Automatically installs the chosen helper if missing
- Supports installation of both `yay` and `paru` from AUR
- Handles prerequisites (base-devel, git)
- Proper error handling and cleanup

### 3. Environment Variable Export
- Sets `AUR_HELPER` environment variable for use in subsequent modules
- Exports variable to make it available to child processes
- Fallback value of `yay` if variable is unset

### 4. Universal Module Support
- Updated all installation modules to use `${AUR_HELPER:-yay}` pattern
- Ensures compatibility with both AUR helpers
- Maintains backward compatibility with existing installations

## Files Modified

### Core Installer Files
1. **`install.sh`** - Main installer with comprehensive features
   - Added `select_aur_helper()` function
   - Added `install_aur_helper()` function
   - Integrated AUR helper selection into main workflow

2. **`installv2.sh`** - Simplified installer
   - Added `select_aur_helper()` function
   - Integrated selection into main workflow

### Installation Module Files
3. **`install/01-yay.sh`** - AUR helper installation module
   - Updated to support both `yay` and `paru`
   - Renamed functions to be AUR helper agnostic
   - Uses `$AUR_HELPER` environment variable

4. **`install/02-core-dev-tools.sh`** - Core development tools
   - Updated AUR package installation commands
   - Uses `${AUR_HELPER:-yay}` pattern

5. **`install/06-dev-tools-utilities.sh`** - Developer utilities
   - Updated all AUR package installation sections
   - Updated condition checks for AUR helper availability
   - Maintained consistent warning messages

6. **`install/07-system-config-themes.sh`** - System themes and configuration
   - Updated all package installation commands
   - Uses `${AUR_HELPER:-yay}` pattern throughout

### Test Files
7. **`test-aur-selection.sh`** - Test script for verification
   - Validates AUR helper selection functionality
   - Tests command construction
   - Verifies environment variable handling

## Command Pattern
All modules now use the standardized pattern:
```bash
${AUR_HELPER:-yay} -S --needed package-name
```

This pattern:
- Uses the selected AUR helper from the environment variable
- Falls back to `yay` if the variable is unset
- Maintains compatibility with existing installations

## Usage Examples

### Command Line Usage (install.sh)
```bash
# Use default selection prompt
./install.sh

# Pre-select AUR helper via command line
./install.sh --aur-helper paru

# Dry run with specific AUR helper
./install.sh --aur-helper yay --dry-run
```

### Environment Variable Usage in Modules
```bash
# Install AUR packages using selected helper
${AUR_HELPER:-yay} -S --needed --noconfirm package-name

# Check if AUR helper is available
if command -v "${AUR_HELPER:-yay}" &> /dev/null; then
    # Install AUR packages
fi
```

## Testing
The implementation has been tested with:
- ✅ Default selection (yay)
- ✅ Paru selection
- ✅ Invalid input handling (fallback to yay)
- ✅ Command construction
- ✅ Environment variable export

## Benefits
1. **User Choice**: Users can select their preferred AUR helper
2. **Consistency**: All modules use the same AUR helper
3. **Fallback Safety**: Automatic fallback to yay for invalid inputs
4. **Backward Compatibility**: Existing installations continue to work
5. **Future Extensibility**: Easy to add support for additional AUR helpers

## Future Enhancements
- Could be extended to support additional AUR helpers (trizen, etc.)
- Could remember user preference for subsequent runs
- Could validate AUR helper availability before selection
