#!/usr/bin/env bash
# install-debian.sh - Debian/Ubuntu specific installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_YAML="$SCRIPT_DIR/packages.yaml"
FUNCTIONS_FILE="$SCRIPT_DIR/install-functions.sh"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[DEBIAN]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Source custom installation functions
if [ -f "$FUNCTIONS_FILE" ]; then
    source "$FUNCTIONS_FILE"
fi

# Detect specific distro (debian vs ubuntu)
detect_specific_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "debian"
    fi
}

# Check if yq is installed
check_yq() {
    if ! command -v yq &> /dev/null; then
        log_warn "yq not found, installing..."
        
        local arch=$(uname -m)
        case "$arch" in
            x86_64) yq_arch="amd64" ;;
            aarch64|arm64) yq_arch="arm64" ;;
            armv7l) yq_arch="arm" ;;
            *) log_error "Unsupported architecture: $arch"; exit 1 ;;
        esac
        
        log_info "Downloading yq binary..."
        sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${yq_arch}"
        sudo chmod +x /usr/local/bin/yq
        
        if ! command -v yq &> /dev/null; then
            log_error "Failed to install yq"
            exit 1
        fi
        
        log_info "yq installed successfully"
    fi
}

# Add PPA repository (Ubuntu)
add_ppa() {
    local ppa="$1"
    log_info "Adding PPA: $ppa"
    sudo add-apt-repository -y "ppa:$ppa"
}

# Install a single package
install_package() {
    local pkg="$1"
    log_info "Installing: $pkg"
    if sudo apt-get install -y "$pkg"; then
        return 0
    else
        log_error "Failed to install: $pkg"
        return 1
    fi
}

# Get package info from YAML
get_package_info() {
    local pkg_name="$1"
    local distro="$1_DISTRO"
    
    # Try distro-specific config (ubuntu or debian)
    local distro_config=$(yq eval ".packages.${pkg_name}.${distro}" "$PACKAGES_YAML" 2>/dev/null)
    
    if [[ "$distro_config" != "null" && -n "$distro_config" ]]; then
        if echo "$distro_config" | grep -q "skip: true"; then
            echo "skip||"
            return
        fi
        
        local package=$(yq eval ".packages.${pkg_name}.${distro}.package" "$PACKAGES_YAML" 2>/dev/null)
        local method=$(yq eval ".packages.${pkg_name}.${distro}.method" "$PACKAGES_YAML" 2>/dev/null)
        
        if [[ "$package" == "null" || -z "$package" ]]; then
            package="$distro_config"
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
    log_info "Starting Debian/Ubuntu package installation"
    
    SPECIFIC_DISTRO=$(detect_specific_distro)
    log_info "Detected: $SPECIFIC_DISTRO"
    
    # Show profile information
    if [[ "$INSTALL_PROFILE" != "full" ]]; then
        log_info "Profile: $INSTALL_PROFILE"
    fi
    if [[ -n "$EXCLUDE_TAGS" ]]; then
        log_info "Excluding: $EXCLUDE_TAGS"
    fi
    
    check_yq
    
    # Update package lists
    log_info "Updating package lists..."
    sudo apt-get update
    
    # Install dependencies
    log_info "Installing common dependencies..."
    sudo apt-get install -y software-properties-common apt-transport-https ca-certificates
    
    # Get all package names
    local packages=$(yq eval '.packages | keys | .[]' "$PACKAGES_YAML")
    
    while IFS= read -r pkg_name; do
        [[ -z "$pkg_name" ]] && continue
        
        # Check if should install based on profile/tags
        if ! should_install_package "$pkg_name"; then
            continue
        fi
        
        # Get package info (try specific distro first)
        IFS='|' read -r package method extra <<< "$(get_package_info "$pkg_name" "$SPECIFIC_DISTRO")"
        
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
                        "$func_name" "$SPECIFIC_DISTRO"
                    else
                        log_error "Custom function $func_name not found!"
                        log_warn "Falling back to standard installation..."
                        install_package "$package"
                    fi
                    ;;
                ppa:*)
                    ppa_repo="${method#ppa:}"
                    add_ppa "$ppa_repo"
                    sudo apt-get update
                    install_package "$package"
                    ;;
                copr|aur|skip)
                    log_warn "Skipping $pkg_name (marked as: $method)"
                    ;;
                snap)
                    log_warn "Snap installation not supported - skipping $pkg_name"
                    log_info "Consider installing manually if needed"
                    ;;
                flatpak|manual)
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
    
    # Upgrade packages
    log_info "Upgrading installed packages..."
    sudo apt-get upgrade -y
    
    log_info "Debian/Ubuntu package installation complete!"
}

main "$@"
