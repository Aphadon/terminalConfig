#!/usr/bin/env bash
# install-macos.sh - macOS (Homebrew) specific installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_YAML="$SCRIPT_DIR/packages.yaml"
FUNCTIONS_FILE="$SCRIPT_DIR/install-functions.sh"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[MACOS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Source custom installation functions
if [ -f "$FUNCTIONS_FILE" ]; then
    source "$FUNCTIONS_FILE"
fi

# Check if Homebrew is installed
check_brew() {
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed!"
        log_info "Install Homebrew from: https://brew.sh"
        log_info "Or run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    log_info "Homebrew found: $(brew --version | head -n1)"
}

# Check if yq is installed
check_yq() {
    if ! command -v yq &> /dev/null; then
        log_warn "yq not found, installing via Homebrew..."
        brew install yq
    fi
}

# Install a single package via Homebrew
install_package() {
    local pkg="$1"
    log_info "Installing: $pkg"
    if brew install "$pkg"; then
        return 0
    else
        log_error "Failed to install: $pkg"
        return 1
    fi
}

# Get package info from YAML
get_package_info() {
    local pkg_name="$1"
    local distro="macos"
    
    # Try macOS-specific config
    local macos_config=$(yq eval ".packages.${pkg_name}.${distro}" "$PACKAGES_YAML" 2>/dev/null)
    
    if [[ "$macos_config" != "null" && -n "$macos_config" ]]; then
        if echo "$macos_config" | grep -q "skip: true"; then
            echo "skip||"
            return
        fi
        
        local package=$(yq eval ".packages.${pkg_name}.${distro}.package" "$PACKAGES_YAML" 2>/dev/null)
        local method=$(yq eval ".packages.${pkg_name}.${distro}.method" "$PACKAGES_YAML" 2>/dev/null)
        
        # If package is null but macos_config exists, use the config as package name
        if [[ "$package" == "null" || -z "$package" ]]; then
            package="$macos_config"
            method="brew"
        fi
        
        [[ "$method" == "null" ]] && method="brew"
        
        echo "${package}|${method}|"
        return
    fi
    
    # Fall back to default
    local default=$(yq eval ".packages.${pkg_name}.default" "$PACKAGES_YAML" 2>/dev/null)
    if [[ "$default" != "null" && -n "$default" ]]; then
        echo "${default}|brew|"
        return
    fi
    
    echo "null||"
}

# Main installation logic
main() {
    log_info "Starting macOS package installation"
    
    check_brew
    check_yq
    
    # Update Homebrew
    log_info "Updating Homebrew..."
    brew update
    
    # Get all package names
    local packages=$(yq eval '.packages | keys | .[]' "$PACKAGES_YAML")
    
    while IFS= read -r pkg_name; do
        [[ -z "$pkg_name" ]] && continue
        
        # Get package info
        IFS='|' read -r package method extra <<< "$(get_package_info "$pkg_name")"
        
        # Skip if no package defined or marked as skip
        if [[ "$package" == "null" || "$package" == "skip" ]]; then
            log_warn "Skipping $pkg_name (not available on macOS)"
            continue
        fi
        
        # Handle installation method
        case "$method" in
            brew)
                install_package "$package"
                ;;
            function)
                func_name="install_${pkg_name//-/_}"
                if declare -f "$func_name" > /dev/null; then
                    log_info "Using custom installation for: $pkg_name"
                    "$func_name" "macos"
                else
                    log_error "Custom function $func_name not found!"
                    log_warn "Falling back to brew installation..."
                    install_package "$package"
                fi
                ;;
            skip)
                log_warn "Skipping $pkg_name (marked as skip)"
                ;;
            *)
                # Default to brew if method is unclear
                install_package "$package"
                ;;
        esac
        
    done <<< "$packages"
    
    # Cleanup
    log_info "Cleaning up Homebrew..."
    brew cleanup
    
    log_info "macOS package installation complete!"
}

main "$@"
