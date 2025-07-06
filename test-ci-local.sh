#!/bin/bash
# Local CI/CD Pipeline Testing Script
# This script mimics the GitHub Actions workflow for local testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test 1: ShellCheck Linting
test_shellcheck() {
    log_info "Running ShellCheck tests..."
    
    if ! command -v shellcheck &> /dev/null; then
        log_error "ShellCheck is not installed. Please install it first."
        log_info "On Arch Linux: sudo pacman -S shellcheck"
        return 1
    fi
    
    local exit_code=0
    local script_count=0
    
    while IFS= read -r script; do
        ((script_count++))
        log_info "Checking $script..."
        if shellcheck -x -e SC1091 "$script"; then
            log_success "✅ ShellCheck passed for $script"
        else
            log_error "❌ ShellCheck failed for $script"
            exit_code=1
        fi
    done < <(find . -name "*.sh" -type f)
    
    log_info "Found $script_count shell scripts"
    
    if [ $exit_code -eq 0 ]; then
        log_success "🎉 All shell scripts passed ShellCheck!"
    else
        log_error "💥 Some shell scripts failed ShellCheck"
    fi
    
    return $exit_code
}

# Test 2: Configuration Validation
test_config_validation() {
    log_info "Running configuration validation..."
    
    # Check for required directories
    local required_dirs=("bin" "config" "install")
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log_error "❌ Missing required directory: $dir"
            return 1
        else
            log_success "✅ Found directory: $dir"
        fi
    done
    
    # Check for main scripts
    local required_scripts=("bootstrap.sh" "install.sh")
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            log_error "❌ Missing required script: $script"
            return 1
        else
            log_success "✅ Found script: $script"
        fi
    done
    
    # Validate install scripts are executable
    for script in install/*.sh; do
        if [ ! -x "$script" ]; then
            log_error "❌ Install script not executable: $script"
            return 1
        else
            log_success "✅ Install script is executable: $script"
        fi
    done
    
    log_success "Configuration validation passed!"
    return 0
}

# Test 3: Docker Container Test
test_docker_container() {
    log_info "Running Docker container tests..."
    
    if ! command -v docker &> /dev/null; then
        log_warning "Docker is not installed. Skipping container tests."
        return 0
    fi
    
    if ! docker info &> /dev/null; then
        log_warning "Docker daemon is not running. Skipping container tests."
        return 0
    fi
    
    log_info "Building test container..."
    if docker build -f Dockerfile.ci -t desktop-setup-test-local .; then
        log_success "✅ Container built successfully"
    else
        log_error "❌ Container build failed"
        return 1
    fi
    
    log_info "Running container validation..."
    if docker run --rm desktop-setup-test-local /home/testuser/validate-environment.sh; then
        log_success "✅ Container validation passed"
    else
        log_error "❌ Container validation failed"
        return 1
    fi
    
    log_info "Running installation tests in container..."
    if docker run --rm desktop-setup-test-local /home/testuser/test-installation.sh; then
        log_success "✅ Container installation tests passed"
    else
        log_error "❌ Container installation tests failed"
        return 1
    fi
    
    # Clean up
    log_info "Cleaning up test container..."
    docker rmi desktop-setup-test-local || true
    
    log_success "Docker container tests completed!"
    return 0
}

# Test 4: Security Scan
test_security_scan() {
    log_info "Running security scan..."
    
    # Look for potential secrets in scripts
    if grep -r -i -E "(password|token|key|secret)" --include="*.sh" . | grep -v "test-ci-local.sh"; then
        log_warning "⚠️  Found potential secrets - please review"
    else
        log_success "✅ No obvious hardcoded secrets found"
    fi
    
    # Check for unsafe practices
    local unsafe_patterns=0
    
    # Check for eval usage
    if grep -r "eval" --include="*.sh" . | grep -v "test-ci-local.sh"; then
        log_warning "⚠️  Found eval usage - review for security"
        ((unsafe_patterns++))
    fi
    
    if [ $unsafe_patterns -eq 0 ]; then
        log_success "✅ No obvious unsafe practices found"
    fi
    
    return 0
}

# Test 5: Integration Test
test_integration() {
    log_info "Running integration tests..."
    
    # Check if scripts handle missing dependencies gracefully
    for script in install/*.sh; do
        if [ -f "$script" ]; then
            log_info "Testing dependency handling in $script..."
            # Check if script has proper error handling
            if grep -q "set -e" "$script"; then
                log_success "✅ $script has error handling"
            else
                log_warning "⚠️  $script missing 'set -e' error handling"
            fi
        fi
    done
    
    # Test utility scripts
    for script in bin/*.sh; do
        if [ -f "$script" ]; then
            log_info "Testing $script..."
            # Test syntax
            if bash -n "$script"; then
                log_success "✅ $script syntax is valid"
            else
                log_error "❌ $script has syntax errors"
                return 1
            fi
        fi
    done
    
    log_success "Integration tests completed!"
    return 0
}

# Generate test report
generate_report() {
    local exit_code=$1
    
    log_info "Generating test report..."
    
    cat > local-test-report.md << EOF
# Local CI/CD Test Report

Generated on: $(date)
Directory: $(pwd)
User: $(whoami)
Host: $(hostname)

## Test Results

- ShellCheck: $([[ ${test_results[shellcheck]} -eq 0 ]] && echo "✅ PASSED" || echo "❌ FAILED")
- Config Validation: $([[ ${test_results[config]} -eq 0 ]] && echo "✅ PASSED" || echo "❌ FAILED")
- Docker Container: $([[ ${test_results[docker]} -eq 0 ]] && echo "✅ PASSED" || echo "❌ FAILED")
- Security Scan: $([[ ${test_results[security]} -eq 0 ]] && echo "✅ PASSED" || echo "❌ FAILED")
- Integration Test: $([[ ${test_results[integration]} -eq 0 ]] && echo "✅ PASSED" || echo "❌ FAILED")

## Repository Statistics

- Total shell scripts: $(find . -name '*.sh' -type f | wc -l)
- Install modules: $(find install -name '*.sh' -type f | wc -l)
- Utility scripts: $(find bin -name '*.sh' -type f | wc -l)
- Configuration files: $(find config -type f | wc -l)

## Overall Status

$([[ $exit_code -eq 0 ]] && echo "🎉 ALL TESTS PASSED" || echo "💥 SOME TESTS FAILED")

EOF
    
    log_success "Test report generated: local-test-report.md"
}

# Main execution
main() {
    log_info "Starting local CI/CD pipeline tests..."
    log_info "Working directory: $(pwd)"
    
    # Initialize test results array
    declare -A test_results
    local overall_exit_code=0
    
    # Run tests
    echo
    if test_shellcheck; then
        test_results[shellcheck]=0
    else
        test_results[shellcheck]=1
        overall_exit_code=1
    fi
    
    echo
    if test_config_validation; then
        test_results[config]=0
    else
        test_results[config]=1
        overall_exit_code=1
    fi
    
    echo
    if test_docker_container; then
        test_results[docker]=0
    else
        test_results[docker]=1
        overall_exit_code=1
    fi
    
    echo
    if test_security_scan; then
        test_results[security]=0
    else
        test_results[security]=1
        overall_exit_code=1
    fi
    
    echo
    if test_integration; then
        test_results[integration]=0
    else
        test_results[integration]=1
        overall_exit_code=1
    fi
    
    echo
    generate_report $overall_exit_code
    
    if [ $overall_exit_code -eq 0 ]; then
        log_success "🎉 All local CI/CD tests passed!"
    else
        log_error "💥 Some local CI/CD tests failed!"
    fi
    
    exit $overall_exit_code
}

# Show help
show_help() {
    cat << EOF
Local CI/CD Pipeline Testing Script

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    --shellcheck-only   Run only ShellCheck tests
    --config-only       Run only configuration validation
    --docker-only       Run only Docker container tests
    --security-only     Run only security scan
    --integration-only  Run only integration tests

This script mimics the GitHub Actions CI/CD pipeline for local testing.
It requires shellcheck and optionally Docker to be installed.

EOF
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --shellcheck-only)
        test_shellcheck
        exit $?
        ;;
    --config-only)
        test_config_validation
        exit $?
        ;;
    --docker-only)
        test_docker_container
        exit $?
        ;;
    --security-only)
        test_security_scan
        exit $?
        ;;
    --integration-only)
        test_integration
        exit $?
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
