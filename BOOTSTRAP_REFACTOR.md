# Bootstrap and Install Script Refactor

This document describes the changes made to unify and improve the bootstrap and install scripts.

## New Unified Bootstrap Script (`bootstrap.sh`)

The new `bootstrap.sh` merges the best features from both `boot.sh` and `bootv2.sh`:

### Key Features:

- **Strict Error Handling**: Uses `set -euo pipefail` for robust error handling
- **Error Traps**: Comprehensive error trap system that provides detailed error reporting
- **Interactive Prompts**: Uses `gum` for better user experience (installs automatically if not present)
- **Repository Update Logic**: Can clone or update the repository from a remote source
- **Comprehensive Logging**: Timestamped logging with different levels (info, success, error, warning)
- **OS Detection**: Automatically detects and reports the operating system
- **Requirements Checking**: Validates git, sudo privileges, and installs gum if needed
- **ASCII Banner**: Professional banner display for better user experience

### Usage:
```bash
./bootstrap.sh
```

The script will automatically handle repository updates, make scripts executable, and call the install script.

## Refactored Install Script (`install.sh`)

The `install.sh` has been completely refactored with significant improvements:

### New Features:

1. **Command-Line Flags**: 
   - `-a, --aur-helper`: Choose between yay, paru, or trizen
   - `-d, --dry-run`: Preview what would be installed without making changes
   - `-v, --verbose`: Enable verbose output for debugging
   - `-h, --help`: Display usage information

2. **Logging Functions**: Consistent timestamped logging throughout
3. **Module Sourcing**: Sources and executes modules in `install/` directory sorted numerically
4. **Error Handling**: Comprehensive error traps with detailed error reporting
5. **AUR Helper Support**: Configurable AUR helper with validation

### Usage Examples:

```bash
# Basic installation with default settings (yay)
./install.sh

# Use paru as AUR helper
./install.sh --aur-helper paru

# Preview installation without making changes
./install.sh --dry-run

# Verbose installation with trizen
./install.sh --aur-helper trizen --verbose

# Show help
./install.sh --help
```

### Module Execution:

The script now automatically discovers and executes all `.sh` files in the `install/` directory:
- Files are sorted numerically (e.g., 01-yay.sh, 02-core-dev-tools.sh, etc.)
- Each module receives the `AUR_HELPER` and `VERBOSE` environment variables
- Modules are sourced (not executed) for better integration
- Progress tracking shows current module and total count

### Error Handling:

- Strict error handling with `set -euo pipefail`
- Error traps that show exact line numbers and exit codes
- Graceful handling of missing or non-executable modules
- Automatic permission fixing for installation modules

### Integration with gum:

- Uses `gum` for interactive confirmations when available
- Falls back to standard prompts if `gum` is not installed
- Consistent theming with warm color scheme

## Migration from Old Scripts

### Deprecated Scripts:
- `boot.sh` → Use `bootstrap.sh`
- `bootv2.sh` → Use `bootstrap.sh`
- `installv2.sh` → Features merged into `install.sh`

### Environment Variables:

The following environment variables can be used to customize behavior:

- `DESKTOP_REF`: Git branch/tag to use (default: main)
- `REPO_URL`: Repository URL for cloning
- `AUR_HELPER`: AUR helper preference (can be overridden with --aur-helper)

### Module Development:

When creating new installation modules:

1. Name them with numeric prefixes (e.g., `08-new-feature.sh`)
2. Make them executable (`chmod +x`)
3. Use the `AUR_HELPER` environment variable for AUR operations
4. Follow the existing logging patterns for consistency
5. Handle errors gracefully with appropriate exit codes

## Benefits of the Refactor

1. **Better User Experience**: Interactive prompts with gum, clear progress indicators
2. **Improved Reliability**: Comprehensive error handling and validation
3. **Flexibility**: Command-line options for different use cases
4. **Maintainability**: Cleaner code structure with reusable functions
5. **Debugging**: Verbose mode and detailed error reporting
6. **Safety**: Dry-run mode for testing changes
7. **Modularity**: Automatic module discovery and execution
8. **Consistency**: Unified logging and error handling across all scripts

The refactored scripts provide a robust foundation for desktop environment setup with enhanced reliability, flexibility, and user experience.
