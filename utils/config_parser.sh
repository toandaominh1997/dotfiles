#!/usr/bin/env bash

###############################################################################
# Enhanced Configuration Parser Utility
# 
# This utility parses configuration files in a simple INI-like format.
# It can extract package lists and plugin configurations with improved
# error handling and validation.
###############################################################################

# Source dependencies
if [[ -z "${DOTFILES_VERSION:-}" ]]; then
    # shellcheck source=../lib/constants.sh
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/constants.sh"
fi

if [[ -z "$(type -t log_info 2>/dev/null)" ]]; then
    # shellcheck source=../lib/logging.sh
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/logging.sh"
fi

# Parse a configuration section and return the items
parse_config_section() {
    local config_file="$1"
    local section_name="$2"
    local output_type="${3:-list}"  # list or associative
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    local in_section=false
    local result=()
    # Note: bash 3.2 doesn't support associative arrays, so we'll use a different approach
    local assoc_result=""
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ $line =~ ^[[:space:]]*$ ]] && continue
        
        # Check for section headers
        if [[ $line =~ ^\[([^]]+)\] ]]; then
            local current_section="${BASH_REMATCH[1]}"
            if [[ $current_section == "$section_name" ]]; then
                in_section=true
            else
                in_section=false
            fi
            continue
        fi
        
        # Process lines in the target section
        if [[ $in_section == true ]]; then
            # Remove leading/trailing whitespace
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            if [[ $output_type == "associative" ]]; then
                # Handle key=value pairs
                if [[ $line =~ ^([^=]+)=(.+)$ ]]; then
                    local key="${BASH_REMATCH[1]}"
                    local value="${BASH_REMATCH[2]}"
                    # Store as newline-separated key=value pairs
                    if [[ -n $assoc_result ]]; then
                        assoc_result="$assoc_result"$'\n'"$key=$value"
                    else
                        assoc_result="$key=$value"
                    fi
                fi
            else
                # Handle simple lists
                if [[ -n $line ]]; then
                    result+=("$line")
                fi
            fi
        fi
    done < "$config_file"
    
    if [[ $output_type == "associative" ]]; then
        # Return associative data as key=value pairs
        if [[ -n $assoc_result ]]; then
            echo "$assoc_result"
        fi
    else
        # Return simple list
        printf '%s\n' "${result[@]}"
    fi
}

# Get packages from configuration file
get_packages_from_config() {
    local config_file="$1"
    local section="$2"
    
    parse_config_section "$config_file" "$section" "list" | tr '\n' ' '
}

# Get plugins from configuration file as associative data
get_plugins_from_config() {
    local config_file="$1"
    local section="$2"
    
    parse_config_section "$config_file" "$section" "associative"
}

# Check if configuration file exists and create default if not
ensure_config_file() {
    local config_file="$1"
    local default_config="$2"
    
    if [[ ! -f "$config_file" ]]; then
        log_warn "Configuration file not found: $config_file"
        if [[ -f "$default_config" ]]; then
            log_info "Creating configuration file from default: $default_config"
            cp "$default_config" "$config_file"
        else
            log_error "Default configuration file not found: $default_config"
            return 1
        fi
    fi
}

# Validate configuration file format
validate_config_file() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    local has_sections=false
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ $line =~ ^[[:space:]]*$ ]] && continue
        
        # Check for section headers
        if [[ $line =~ ^\[([^]]+)\] ]]; then
            has_sections=true
            break
        fi
    done < "$config_file"
    
    if [[ $has_sections == false ]]; then
        log_error "Invalid configuration file format: no sections found"
        return 1
    fi
    
    log_debug "Configuration file validation passed: $config_file"
    return 0
} 