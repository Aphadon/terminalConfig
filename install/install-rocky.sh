#!/usr/bin/env bash
# install-rocky.sh - Rocky Linux / RHEL specific installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_YAML="$SCRIPT_DIR/packages.yaml"
FUNCTIONS_FILE="$SCRIPT_DIR/install-functions.sh"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[ROCKY]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Source custom installation functions
if [ -f "$FUNCTIONS_FILE" ]; then
    source "$FUNCTIONS_FILE"
fi

# Check if yq is installed, if not try to install it
check_yq() {
    if ! command -v yq &> /dev/null; then
        log_warn "yq not found, attempting to install..."
        sudo dnf install -y yq || {
            log_error "Failed to install yq. Please install it manually."
            exit 1
        }
    fi
}

# Enable EPEL repository
enable_epel() {
    if ! dnf repolist | grep -q "epel"; then
        log_info "Enabling EPEL repository..."
        sudo dnf install -y epel-release
    else
        log_info "EPEL already enabled"
    fi
}

# Enable COPR repository
enable_copr() {
    local repo="$1"
    log_info "Enabling COPR: $repo"
    if ! sudo dnf copr list | grep -q "$repo"; then
        sudo dnf -y copr enable "$repo"
    else
        log_warn "COPR $repo already enabled"
    fi
}

# Install a single package
install_package() {
    local pkg="$1"
    log_info "Installing: $pkg"
    if sudo dnf -y install "$pkg"; then
        return 0
    else
        log_error "Failed to install: $pkg"
        return 1
    fi
}

# Get package info from YAML
get_package_info() {
    local pkg_name="$1"
    local distro="rocky"
    
    # Try rocky-specific config
    local rocky_config=$(yq eval ".packages.${pkg_name}.${distro}" "$PACKAGES_YAML" 2>/dev/null)
    
    if [[ "$rocky_config" != "null" && -n "$rocky_config" ]]; then
        if echo "$rocky_config" | grep -q "skip: true"; then
            echo "skip||"
            return
        fi
        
        local package=$(yq eval ".packages.${pkg_name}.${distro}.package" "$PACKAGES_YAML" 2>/dev/null)
        local method=$(yq eval ".packages.${pkg_name}.${distro}.method" "$PACKAGES_YAML" 2>/dev/null)
        
        if [[ "$package" == "null" || -z "$package" ]]; then
            package="$rocky_config"
            method="null"
        fi
        
        echo "${package}|${method}|"
        return
    fi
    
    # Fall back to default
    local default=$(yq eval ".packages.${pkg_name}.default" "$PACKAGES_YAML" 2>/dev/null)
    if [[ "$default" != "null" && -n "$default" ]]; then
        echo "${default}||"
        return
    fi
    
    echo "null||"
}

# Main installation logic
main() {
    log_info "Starting Rocky Linux / RHEL package installation"
    
    check_yq
    
    # Update system and enable EPEL
    log_info "Updating system packages..."
    sudo dnf -y update
    enable_epel
    
    # Track enabled COPRs
    declare -A enabled_coprs
    
    # Get all package names
    local packages=$(yq eval '.packages | keys | .[]' "$PACKAGES_YAML")
    
    while IFS= read -r pkg_name; do
        [[ -z "$pkg_name" ]] && continue
        
        # Get package info
        IFS='|' read -r package method extra <<< "$(get_package_info "$pkg_name")"
        
        # Skip if no package defined
        if [[ "$package" == "null" || "$package" == "skip" ]]; then
            log_warn "Skipping $pkg_name"
            continue
        fi
        
        # Handle installation method
        if [[ -n "$method" && "$method" != "null" ]]; then
            case "$method" in
                function)
                    func_name="install_${pkg_name//-/_}"
                    if declare -f "$func_name" > /dev/null; then
                        log_info "Using custom installation for: $pkg_name"
                        "$func_name" "rocky"
                    else
                        log_error "Custom function $func_name not found!"
                        log_warn "Falling back to standard installation..."
                        install_package "$package"
                    fi
                    ;;
                copr:*)
                    copr_repo="${method#copr:}"
                    if [[ -z "${enabled_coprs[$copr_repo]}" ]]; then
                        enable_copr "$copr_repo"
                        enabled_coprs[$copr_repo]=1
                    fi
                    install_package "$package"
                    ;;
                skip)
                    log_warn "Skipping $pkg_name (marked as skip)"
                    ;;
                *)
                    install_package "$package"
                    ;;
            esac
        else
            install_package "$package"
        fi
        
    done <<< "$packages"
    
    log_info "Rocky Linux / RHEL package installation complete!"
}

main "$@"
