#!/bin/bash
# logging.sh - Shared logging library for desktop-setup project
# Provides consistent, timestamped logging functions across all scripts

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions with timestamps
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Additional logging functions for specific contexts
log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG:${NC} $1"
    fi
}

# Legacy function aliases for backwards compatibility
print_status() {
    log_info "$1"
}

print_warning() {
    log_warning "$1"
}

print_error() {
    log_error "$1"
}

print_header() {
    log "$1"
}

# Function to set up error handling with logging
setup_error_handling() {
    set -euo pipefail
    
    # Error trap function
    handle_error() {
        local exit_code=$?
        local line_number=$1
        
        log_error "Script failed at line $line_number with exit code $exit_code"
        exit $exit_code
    }
    
    # Set error trap
    trap 'handle_error $LINENO' ERR
}

# Function to log script start
log_script_start() {
    local script_name="${1:-$(basename "$0")}"
    log "Starting $script_name"
}

# Function to log script completion
log_script_end() {
    local script_name="${1:-$(basename "$0")}"
    log_success "$script_name completed successfully"
}
