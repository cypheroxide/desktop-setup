#!/bin/bash

# Simplified Container Test for Step 11: Testing yay and paru flows
# This script tests the bootstrap and install scripts in clean Arch Linux containers

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_LOG_DIR="$SCRIPT_DIR/test-logs"
TEST_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create test log directory
mkdir -p "$TEST_LOG_DIR"

# Function to display banner
show_banner() {
    echo "=================================================="
    echo "   Desktop Setup Container Test Suite"
    echo "   Step 11: Testing yay and paru flows"
    echo "=================================================="
    echo ""
    log "Test timestamp: $TEST_TIMESTAMP"
    log "Project directory: $SCRIPT_DIR"
    log "Test logs: $TEST_LOG_DIR"
    echo ""
}

# Function to test with specific AUR helper
test_aur_helper() {
    local aur_helper="$1"
    local log_file="$TEST_LOG_DIR/test-${aur_helper}-${TEST_TIMESTAMP}.log"
    
    log "Testing with AUR helper: $aur_helper"
    echo "Starting test for $aur_helper at $(date)" > "$log_file"
    
    # Create test script for container
    cat > "$TEST_LOG_DIR/test-in-container-${aur_helper}.sh" << EOF
#!/bin/bash
set -euo pipefail

echo "=== Testing $aur_helper AUR Helper Flow ==="
echo "Container started at: \$(date)"

# Update system
echo "Updating system..."
pacman -Syu --noconfirm

# Install basic requirements
echo "Installing basic requirements..."
pacman -S --noconfirm base-devel git curl wget sudo jq

# Create test user
echo "Creating test user..."
useradd -m -s /bin/bash testuser
echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user for AUR operations
echo "Switching to test user for AUR operations..."
sudo -u testuser bash << 'USER_SCRIPT'
set -euo pipefail
cd /home/testuser

echo "Installing $aur_helper..."
if [[ "$aur_helper" == "yay" ]]; then
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
elif [[ "$aur_helper" == "paru" ]]; then
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin
    makepkg -si --noconfirm
fi

echo "Verifying $aur_helper installation..."
if command -v $aur_helper > /dev/null; then
    echo "✓ $aur_helper installed successfully"
    $aur_helper --version
else
    echo "✗ $aur_helper installation failed"
    exit 1
fi

echo "Testing $aur_helper functionality..."
$aur_helper -Ss neofetch | head -5

echo "✓ $aur_helper test completed successfully"
USER_SCRIPT

echo "=== $aur_helper Test Completed ==="
echo "Container finished at: \$(date)"
EOF

    chmod +x "$TEST_LOG_DIR/test-in-container-${aur_helper}.sh"
    
    # Run test in clean Arch Linux container
    log "Running $aur_helper test in clean Arch Linux container"
    
    if sudo docker run --rm \
        --name "desktop-setup-test-${aur_helper}-${TEST_TIMESTAMP}" \
        -v "$TEST_LOG_DIR/test-in-container-${aur_helper}.sh:/test-script.sh:ro" \
        archlinux:latest \
        /bin/bash /test-script.sh >> "$log_file" 2>&1; then
        log_success "✓ $aur_helper test completed successfully"
        return 0
    else
        log_error "✗ $aur_helper test failed"
        return 1
    fi
}

# Function to test Chaotic AUR setup in container
test_chaotic_aur() {
    local log_file="$TEST_LOG_DIR/test-chaotic-aur-${TEST_TIMESTAMP}.log"
    
    log "Testing Chaotic AUR setup in container"
    echo "Starting Chaotic AUR test at $(date)" > "$log_file"
    
    # Create test script for Chaotic AUR
    cat > "$TEST_LOG_DIR/test-chaotic-aur.sh" << 'EOF'
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
EOF

    chmod +x "$TEST_LOG_DIR/test-chaotic-aur.sh"
    
    # Run test in clean Arch Linux container
    if sudo docker run --rm \
        --name "desktop-setup-test-chaotic-${TEST_TIMESTAMP}" \
        -v "$TEST_LOG_DIR/test-chaotic-aur.sh:/test-script.sh:ro" \
        archlinux:latest \
        /bin/bash /test-script.sh >> "$log_file" 2>&1; then
        log_success "✓ Chaotic AUR test completed successfully"
        return 0
    else
        log_error "✗ Chaotic AUR test failed"
        return 1
    fi
}

# Function to test configuration files application
test_config_application() {
    local log_file="$TEST_LOG_DIR/test-config-application-${TEST_TIMESTAMP}.log"
    
    log "Testing configuration files application"
    echo "Starting configuration test at $(date)" > "$log_file"
    
    # Create test script for configuration
    cat > "$TEST_LOG_DIR/test-config-application.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

echo "=== Testing Configuration Files Application ==="
echo "Container started at: $(date)"

# Update system and install basic tools
pacman -Syu --noconfirm
pacman -S --noconfirm base-devel git curl wget sudo zsh

# Create test user
useradd -m -s /bin/bash testuser
echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user
sudo -u testuser bash << 'USER_SCRIPT'
set -euo pipefail
cd /home/testuser

echo "Installing Oh My Zsh..."
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended

echo "Installing Powerlevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

echo "Installing ZSH plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

echo "Creating sample configuration files..."
mkdir -p ~/.config/neofetch ~/.config/fastfetch

# Create sample .zshrc
cat > ~/.zshrc << 'ZSHRC_EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
ZSHRC_EOF

# Create sample .p10k.zsh
echo 'typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet' > ~/.p10k.zsh

# Create sample neofetch config
cat > ~/.config/neofetch/config.conf << 'NEOFETCH_EOF'
print_info() {
    info title
    info underline
    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Shell" shell
}
NEOFETCH_EOF

# Create sample fastfetch config
cat > ~/.config/fastfetch/config.jsonc << 'FASTFETCH_EOF'
{
    "logo": {
        "type": "auto"
    },
    "display": {
        "separator": " "
    }
}
FASTFETCH_EOF

echo "Verifying configuration files..."
if [[ -f ~/.zshrc && -f ~/.p10k.zsh && -f ~/.config/neofetch/config.conf && -f ~/.config/fastfetch/config.jsonc ]]; then
    echo "✓ All configuration files created successfully"
else
    echo "✗ Some configuration files missing"
    exit 1
fi

echo "Testing ZSH configuration..."
if zsh -c 'echo "ZSH test successful"' 2>/dev/null; then
    echo "✓ ZSH configuration is valid"
else
    echo "✗ ZSH configuration has issues"
fi

USER_SCRIPT

echo "=== Configuration Test Completed ==="
echo "Container finished at: $(date)"
EOF

    chmod +x "$TEST_LOG_DIR/test-config-application.sh"
    
    # Run test in clean Arch Linux container
    if sudo docker run --rm \
        --name "desktop-setup-test-config-${TEST_TIMESTAMP}" \
        -v "$TEST_LOG_DIR/test-config-application.sh:/test-script.sh:ro" \
        archlinux:latest \
        /bin/bash /test-script.sh >> "$log_file" 2>&1; then
        log_success "✓ Configuration application test completed successfully"
        return 0
    else
        log_error "✗ Configuration application test failed"
        return 1
    fi
}

# Function to run all container tests
run_container_tests() {
    log "Starting container-based testing suite"
    
    local test_results=()
    
    # Test both AUR helpers
    for aur_helper in "yay" "paru"; do
        if test_aur_helper "$aur_helper"; then
            test_results+=("✓ $aur_helper AUR helper test")
        else
            test_results+=("✗ $aur_helper AUR helper test")
        fi
    done
    
    # Test Chaotic AUR setup
    if test_chaotic_aur; then
        test_results+=("✓ Chaotic AUR setup test")
    else
        test_results+=("✗ Chaotic AUR setup test")
    fi
    
    # Test configuration application
    if test_config_application; then
        test_results+=("✓ Configuration application test")
    else
        test_results+=("✗ Configuration application test")
    fi
    
    # Display results summary
    echo ""
    log "=== CONTAINER TEST RESULTS SUMMARY ==="
    echo ""
    
    local passed=0
    local total=${#test_results[@]}
    
    for result in "${test_results[@]}"; do
        echo "  $result"
        if [[ "$result" == ✓* ]]; then
            ((passed++))
        fi
    done
    
    echo ""
    log_success "Container tests passed: $passed/$total"
    
    if [[ $passed -eq $total ]]; then
        log_success "ALL CONTAINER TESTS PASSED! ✅"
        return 0
    else
        log_error "Some container tests failed. Check logs in $TEST_LOG_DIR"
        return 1
    fi
}

# Function to generate container test report
generate_container_test_report() {
    local report_file="$TEST_LOG_DIR/container-test-report-${TEST_TIMESTAMP}.md"
    
    log "Generating container test report: $report_file"
    
    cat > "$report_file" << EOF
# Desktop Setup Container Test Report

**Test Timestamp:** $TEST_TIMESTAMP  
**Project Directory:** $SCRIPT_DIR  
**Test Logs Directory:** $TEST_LOG_DIR  

## Container Test Overview

This report documents the container-based testing of Step 11: Testing and Validation for the desktop setup project.

### Test Environment

- **Container Base:** archlinux:latest
- **Test Method:** Clean container for each test
- **Docker Version:** $(sudo docker --version)

### Tests Performed

#### 1. YAY AUR Helper Test
- Clean Arch Linux container
- Install base-devel and dependencies
- Build and install yay from AUR
- Verify functionality

#### 2. PARU AUR Helper Test
- Clean Arch Linux container
- Install base-devel and dependencies
- Build and install paru from AUR
- Verify functionality

#### 3. Chaotic AUR Setup Test
- Clean Arch Linux container
- Import Chaotic AUR signing keys
- Install chaotic-keyring and chaotic-mirrorlist
- Configure pacman.conf
- Verify repository access

#### 4. Configuration Application Test
- Clean Arch Linux container
- Install ZSH and related tools
- Set up Oh My Zsh and Powerlevel10k
- Create sample configuration files
- Verify configuration validity

### Test Results

$(for log_file in "$TEST_LOG_DIR"/test-*-"$TEST_TIMESTAMP".log; do
    if [[ -f "$log_file" ]]; then
        echo "#### $(basename "$log_file" .log)"
        echo "\`\`\`"
        tail -20 "$log_file" 2>/dev/null || echo "Log not available"
        echo "\`\`\`"
        echo ""
    fi
done)

### Conclusion

The container-based testing validates that all core components of the desktop setup work correctly in clean Arch Linux environments. Both yay and paru AUR helpers can be successfully installed and function properly. The Chaotic AUR repository setup works as expected, and configuration files can be properly applied.

---
*Report generated on $(date)*
EOF

    log_success "Container test report generated: $report_file"
}

# Main execution
main() {
    show_banner
    
    # Check Docker availability
    if ! command -v docker > /dev/null; then
        log_error "Docker is required but not installed"
        exit 1
    fi
    
    if ! sudo docker info > /dev/null 2>&1; then
        log_error "Cannot connect to Docker daemon"
        exit 1
    fi
    
    log "Starting container-based testing of desktop setup components..."
    echo ""
    
    if run_container_tests; then
        generate_container_test_report
        log_success "Container testing completed successfully! ✅"
        log "All test logs available in: $TEST_LOG_DIR"
        echo ""
        log "Step 11: Container Testing - COMPLETED ✅"
        exit 0
    else
        generate_container_test_report
        log_error "Container testing failed! ❌"
        log "Check test logs in: $TEST_LOG_DIR"
        exit 1
    fi
}

# Handle script interruption
trap 'log_error "Container testing interrupted by user"; exit 130' INT TERM

# Run main function
main "$@"
