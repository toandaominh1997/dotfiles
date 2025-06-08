#!/usr/bin/env bash

###############################################################################
# Comprehensive Test Suite for Enhanced Dotfiles Setup
# 
# This script tests various aspects of the dotfiles setup including:
# - Script syntax validation
# - Configuration file parsing
# - Dry-run functionality
# - Cross-platform compatibility
# - Error handling
###############################################################################

set -euo pipefail

# Test configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(dirname "$SCRIPT_DIR")"
readonly SETUP_SCRIPT="$ROOT_DIR/setup.sh"
readonly CONFIG_DIR="$ROOT_DIR/config"
readonly TEMP_TEST_DIR="/tmp/dotfiles-test-$$"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Test output functions
test_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

test_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test setup and cleanup
setup_test_environment() {
    test_info "Setting up test environment..."
    mkdir -p "$TEMP_TEST_DIR"
    export TEST_MODE=true
}

cleanup_test_environment() {
    test_info "Cleaning up test environment..."
    rm -rf "$TEMP_TEST_DIR" || true
}

# Individual test functions
test_script_syntax() {
    test_info "Testing script syntax..."
    ((TESTS_RUN++))
    
    if bash -n "$SETUP_SCRIPT"; then
        test_pass "Setup script syntax is valid"
    else
        test_fail "Setup script has syntax errors"
        return 1
    fi
    
    # Test utility scripts
    for script in "$SCRIPT_DIR"/*.sh; do
        if [[ -f "$script" && "$script" != "${BASH_SOURCE[0]}" ]]; then
            ((TESTS_RUN++))
            if bash -n "$script"; then
                test_pass "$(basename "$script") syntax is valid"
            else
                test_fail "$(basename "$script") has syntax errors"
            fi
        fi
    done
}

test_configuration_files() {
    test_info "Testing configuration files..."
    ((TESTS_RUN++))
    
    local packages_config="$CONFIG_DIR/packages.conf"
    if [[ -f "$packages_config" ]]; then
        test_pass "Package configuration file exists"
        
        # Test configuration parsing
        ((TESTS_RUN++))
        if source "$SCRIPT_DIR/config_parser.sh" 2>/dev/null; then
            test_pass "Configuration parser loads successfully"
            
            # Test section parsing
            local sections=("required_packages" "formula_packages" "cask_packages" "zsh_plugins" "themes" "tmux_plugins")
            for section in "${sections[@]}"; do
                ((TESTS_RUN++))
                if parse_config_section "$packages_config" "$section" >/dev/null 2>&1; then
                    test_pass "Configuration section '$section' is valid"
                else
                    test_fail "Configuration section '$section' is invalid"
                fi
            done
        else
            test_fail "Configuration parser failed to load"
        fi
    else
        test_fail "Package configuration file not found"
    fi
}

test_dry_run_mode() {
    test_info "Testing dry-run mode..."
    ((TESTS_RUN++))
    
    # Create a temporary log file
    local log_file="$TEMP_TEST_DIR/dry-run.log"
    
    if "$SETUP_SCRIPT" --dry-run > "$log_file" 2>&1; then
        test_pass "Dry-run mode executes successfully"
        
        # Check for dry-run indicators in output
        ((TESTS_RUN++))
        if grep -q "\[DRY RUN\]" "$log_file"; then
            test_pass "Dry-run mode produces expected output"
        else
            test_fail "Dry-run mode output doesn't contain expected markers"
        fi
    else
        test_fail "Dry-run mode failed to execute"
    fi
}

test_help_functionality() {
    test_info "Testing help functionality..."
    ((TESTS_RUN++))
    
    if "$SETUP_SCRIPT" --help >/dev/null 2>&1; then
        test_pass "Help option works correctly"
    else
        test_fail "Help option failed"
    fi
}

test_argument_parsing() {
    test_info "Testing argument parsing..."
    
    local test_args=("--upgrade" "--verbose" "--dry-run" "--help")
    for arg in "${test_args[@]}"; do
        ((TESTS_RUN++))
        if "$SETUP_SCRIPT" "$arg" --dry-run >/dev/null 2>&1 || [[ "$arg" == "--help" ]]; then
            test_pass "Argument '$arg' is recognized"
        else
            test_fail "Argument '$arg' is not recognized"
        fi
    done
    
    # Test invalid arguments
    ((TESTS_RUN++))
    if ! "$SETUP_SCRIPT" --invalid-argument >/dev/null 2>&1; then
        test_pass "Invalid arguments are properly rejected"
    else
        test_fail "Invalid arguments are not properly rejected"
    fi
}

test_os_detection() {
    test_info "Testing OS detection..."
    ((TESTS_RUN++))
    
    # Source the setup script to get access to functions
    if source "$SETUP_SCRIPT" --dry-run >/dev/null 2>&1; then
        local detected_os
        detected_os=$(detect_os)
        if [[ "$detected_os" == "macos" || "$detected_os" == "linux" ]]; then
            test_pass "OS detection works correctly (detected: $detected_os)"
        else
            test_fail "OS detection failed (detected: $detected_os)"
        fi
    else
        test_fail "Could not source setup script for OS detection test"
    fi
}

test_utility_functions() {
    test_info "Testing utility functions..."
    
    # Test command existence check
    ((TESTS_RUN++))
    if command_exists bash; then
        test_pass "command_exists function works for existing commands"
    else
        test_fail "command_exists function failed for bash"
    fi
    
    ((TESTS_RUN++))
    if ! command_exists nonexistent_command_12345; then
        test_pass "command_exists function works for non-existing commands"
    else
        test_fail "command_exists function incorrectly reported non-existing command as existing"
    fi
}

test_backup_functionality() {
    test_info "Testing backup functionality..."
    ((TESTS_RUN++))
    
    # Create a test file
    local test_file="$TEMP_TEST_DIR/test_config"
    echo "test content" > "$test_file"
    
    # Source the setup script to get backup_file function
    source "$SETUP_SCRIPT" --dry-run >/dev/null 2>&1 || true
    
    if backup_file "$test_file" 2>/dev/null; then
        if ls "${test_file}.backup."* >/dev/null 2>&1; then
            test_pass "Backup functionality works correctly"
        else
            test_fail "Backup file was not created"
        fi
    else
        test_fail "Backup functionality failed"
    fi
}

test_logging_system() {
    test_info "Testing logging system..."
    ((TESTS_RUN++))
    
    local log_file="$TEMP_TEST_DIR/logging.log"
    
    # Test verbose mode
    if "$SETUP_SCRIPT" --verbose --dry-run > "$log_file" 2>&1; then
        if grep -q "\[DEBUG\]" "$log_file"; then
            test_pass "Verbose logging works correctly"
        else
            test_fail "Verbose logging does not produce debug output"
        fi
    else
        test_fail "Verbose mode failed to execute"
    fi
}

test_idempotency() {
    test_info "Testing idempotency (safe to run multiple times)..."
    ((TESTS_RUN++))
    
    # Run dry-run mode twice and compare outputs
    local log1="$TEMP_TEST_DIR/run1.log"
    local log2="$TEMP_TEST_DIR/run2.log"
    
    "$SETUP_SCRIPT" --dry-run > "$log1" 2>&1
    "$SETUP_SCRIPT" --dry-run > "$log2" 2>&1
    
    # The outputs should be similar (allowing for timestamps)
    if diff -u "$log1" "$log2" | grep -v "^\[.*\]" >/dev/null; then
        test_pass "Script appears to be idempotent"
    else
        test_warn "Script outputs differ between runs (may not be idempotent)"
    fi
}

# Integration tests
test_full_dry_run() {
    test_info "Running full dry-run integration test..."
    ((TESTS_RUN++))
    
    local log_file="$TEMP_TEST_DIR/full-dry-run.log"
    
    if timeout 300 "$SETUP_SCRIPT" --dry-run --verbose > "$log_file" 2>&1; then
        # Check for expected sections in the output
        local expected_sections=("Homebrew" "packages" "Oh My Zsh" "configurations")
        local all_found=true
        
        for section in "${expected_sections[@]}"; do
            if ! grep -qi "$section" "$log_file"; then
                test_warn "Expected section '$section' not found in dry-run output"
                all_found=false
            fi
        done
        
        if [[ "$all_found" == true ]]; then
            test_pass "Full dry-run integration test completed successfully"
        else
            test_warn "Full dry-run completed but some expected sections were missing"
        fi
    else
        test_fail "Full dry-run integration test failed or timed out"
    fi
}

# Performance tests
test_performance() {
    test_info "Testing performance..."
    ((TESTS_RUN++))
    
    local start_time
    start_time=$(date +%s)
    
    "$SETUP_SCRIPT" --dry-run >/dev/null 2>&1
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $duration -lt 60 ]]; then
        test_pass "Dry-run completes in reasonable time ($duration seconds)"
    else
        test_warn "Dry-run took longer than expected ($duration seconds)"
    fi
}

# Main test runner
run_all_tests() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                     Enhanced Dotfiles Test Suite                           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    setup_test_environment
    
    # Run all tests
    test_script_syntax
    test_configuration_files
    test_help_functionality
    test_argument_parsing
    test_os_detection
    test_utility_functions
    test_backup_functionality
    test_logging_system
    test_dry_run_mode
    test_idempotency
    test_full_dry_run
    test_performance
    
    cleanup_test_environment
    
    # Print summary
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                              Test Summary                                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "Tests run:    ${TESTS_RUN}"
    echo -e "Tests passed: ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Tests failed: ${RED}${TESTS_FAILED}${NC}"
    echo -e "Success rate: $(( TESTS_PASSED * 100 / TESTS_RUN ))%"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some tests failed. Please review the output above.${NC}"
        return 1
    fi
}

# Allow running individual tests
if [[ $# -gt 0 ]]; then
    case "$1" in
        syntax)
            setup_test_environment
            test_script_syntax
            cleanup_test_environment
            ;;
        config)
            setup_test_environment
            test_configuration_files
            cleanup_test_environment
            ;;
        dry-run)
            setup_test_environment
            test_dry_run_mode
            cleanup_test_environment
            ;;
        *)
            echo "Unknown test: $1"
            echo "Available tests: syntax, config, dry-run"
            echo "Run without arguments to run all tests"
            exit 1
            ;;
    esac
else
    run_all_tests
fi