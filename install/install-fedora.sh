#!/usr/bin/env bash
# install-fedora.sh - Fedora/Nobara specific installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_YAML="$SCRIPT_DIR/packages.yaml"
FUNCTIONS_FILE="$SCRIPT_DIR/install-functions.sh"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[FEDORA]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Source custom installation functions
if [ -f "$FUNCTIONS_FILE" ]; then
    source "$FUNCTIONS_FILE"
fi

# Check if yq is installed
check_yq() {
    if ! command -v yq &> /dev/null; then
        log_warn "yq not found, installing..."
        sudo dnf install -y yq
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
    local distro="fedora"
    
    # Try fedora-specific config
    local fedora_config=$(yq eval ".packages.${pkg_name}.${distro}" "$PACKAGES_YAML" 2>/dev/null)
    
    if [[ "$fedora_config" != "null" && -n "$fedora_config" ]]; then
        if echo "$fedora_config" | grep -q "skip: true"; then
            echo "skip||"
            return
        fi
        
        local package=$(yq eval ".packages.${pkg_name}.${distro}.package" "$PACKAGES_YAML" 2>/dev/null)
        local method=$(yq eval ".packages.${pkg_name}.${distro}.method" "$PACKAGES_YAML" 2>/dev/null)
        
        if [[ "$package" == "null" || -z "$package" ]]; then
            package="$fedora_config"
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

# Check if package should be installed based on profile/tags
should_install_package() {
    local pkg_name="$1"
    local tags=$(yq eval ".packages.${pkg_name}.tags[]" "$PACKAGES_YAML" 2>/dev/null)
    
    # No tags defined = always install (for backwards compatibility)
    if [[ -z "$tags" || "$tags" == "null" ]]; then
        return 0
    fi
    
    # Check excluded tags first
    if [[ -n "$EXCLUDE_TAGS" ]]; then
        for exclude_tag in ${EXCLUDE_TAGS//,/ }; do
            if echo "$tags" | grep -q "^${exclude_tag}$"; then
                log_warn "Excluding $pkg_name (tag: $exclude_tag)"
                return 1
            fi
        done
    fi
    
    # If profile is "full", install everything not excluded
    if [[ "$INSTALL_PROFILE" == "full" ]]; then
        return 0
    fi
    
    # Check if any package tag matches any profile tag
    for profile_tag in ${INSTALL_PROFILE//,/ }; do
        if echo "$tags" | grep -q "^${profile_tag}$"; then
            return 0
        fi
    done
    
    # Package doesn't match profile
    return 1
}

# Main installation logic
main() {
    log_info "Starting Fedora/Nobara package installation"
    
    # Show profile information
    if [[ "$INSTALL_PROFILE" != "full" ]]; then
        log_info "Profile: $INSTALL_PROFILE"
    fi
    if [[ -n "$EXCLUDE_TAGS" ]]; then
        log_info "Excluding: $EXCLUDE_TAGS"
    fi
    
    check_yq
    
    # Update system first
    log_info "Updating system packages..."
    sudo dnf -y update
    
    # Enable RPM Fusion if not already enabled
    if ! dnf repolist | grep -q "rpmfusion"; then
        log_info "Enabling RPM Fusion repositories..."
        sudo dnf -y install \
            https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    fi
    
    # Track enabled COPRs to avoid duplicates
    declare -A enabled_coprs
    
    # Get all package names
    local packages=$(yq eval '.packages | keys | .[]' "$PACKAGES_YAML")
    
    while IFS= read -r pkg_name; do
        [[ -z "$pkg_name" ]] && continue
        
        # Check if should install based on profile/tags
        if ! should_install_package "$pkg_name"; then
            continue
        fi
        
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
                        "$func_name" "fedora"
                    else
                        log_error "Custom function $func_name not found!"
                        log_warn "Falling back to standard installation..."
                        install_package "$package"
                    fi
                    ;;
                copr:*)
                    copr_repo="${method#copr:}"
                    # Only enable COPR once
                    if [[ -z "${enabled_coprs[$copr_repo]}" ]]; then
                        enable_copr "$copr_repo"
                        enabled_coprs[$copr_repo]=1
                    fi
                    install_package "$package"
                    ;;
                aur|skip)
                    log_warn "Skipping $pkg_name (marked as: $method)"
                    ;;
                snap|flatpak|manual)
                    log_warn "Manual installation may be required for: $pkg_name ($method)"
                    ;;
                *)
                    install_package "$package"
                    ;;
            esac
        else
            install_package "$package"
        fi
        
    done <<< "$packages"
    
    log_info "Fedora/Nobara package installation complete!"
}

main "$@"
