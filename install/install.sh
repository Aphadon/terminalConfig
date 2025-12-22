#!/usr/bin/env bash
# install.sh - Main installation script for terminal configuration
# Usage: ./install.sh [OPTIONS]
#
# Options:
#   --profile <profile>    Install specific profile (core, dev, desktop, server)
#   --exclude <tags>       Exclude packages with specific tags
#   --help                 Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
CYAN='\033[0;36m'

print_logo() {
  printf "${CYAN}%s${NC}\n" "
    _    ____  _   _    _    ____   ___  _   _
   / \  |  _ \| | | |  / \  |  _ \ / _ \| \ | |
  / _ \ | |_) | |_| | / _ \ | | | | | | |  \| |
 / ___ \|  __/|  _  |/ ___ \| |_| | |_| | |\  |
/_/   \_\_|   |_| |_/_/   \_\____/ \___/|_| \_|
                  A  P  H  A  D  O  N
"
}

# Default settings
INSTALL_PROFILE="full"
EXCLUDE_TAGS=""


log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
${BLUE}Terminal Configuration Installer${NC}

Usage: $0 [OPTIONS]

${BLUE}Options:${NC}
  --profile <tags>       Install packages with specific tags (comma-separated)
                         Examples: core, dev, desktop, server
                         Default: full (installs everything)
  
  --exclude <tags>       Exclude packages with specific tags (comma-separated)
                         Examples: gui, optional
  
  --help                 Show this help message

${BLUE}Common Profiles:${NC}
  full                   Install everything (default)
  core                   Essential tools only (git, curl, tmux, neovim, yazi)
  core,dev               Core + development tools (lazygit, ripgrep, fd, etc.)
  core,dev,desktop       Core + dev + GUI apps (ghostty, etc.)
  core,server            Core + server tools (docker, etc.)

${BLUE}Examples:${NC}
  $0                                    # Install everything
  $0 --profile core                     # Minimal installation
  $0 --profile core,dev                 # Core + dev tools
  $0 --profile core,dev,desktop         # Desktop workstation
  $0 --profile core,server              # Server installation
  $0 --exclude gui                      # Everything except GUI apps
  $0 --profile core,dev --exclude optional  # Core + dev, skip optional

${BLUE}Tags:${NC}
  core       Essential utilities (git, curl, neovim, tmux, yazi)
  dev        Development tools (lazygit, ripgrep, fd, bat, eza)
  desktop    Desktop applications
  gui        GUI applications (requires display)
  server     Server-specific tools (docker, nginx, etc.)
  optional   Nice-to-have packages

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            INSTALL_PROFILE="$2"
            shift 2
            ;;
        --exclude)
            EXCLUDE_TAGS="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Export for use in distro scripts
export INSTALL_PROFILE
export EXCLUDE_TAGS

# Detect OS and distribution
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
        return
    fi
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        log_error "Cannot detect OS (no /etc/os-release)."
        exit 1
    fi
}

# Main installation logic
main() {
    log_info "Starting terminal configuration installation..."
    
    # Show profile info
    if [[ "$INSTALL_PROFILE" != "full" ]]; then
        log_info "Installation profile: $INSTALL_PROFILE"
    fi
    if [[ -n "$EXCLUDE_TAGS" ]]; then
        log_info "Excluding tags: $EXCLUDE_TAGS"
    fi
    
    OS=$(detect_os)
    log_info "Detected OS: $OS"
    
    case "$OS" in
        macos)
            log_info "Using macOS (Homebrew) installation script"
            bash "$SCRIPT_DIR/install-macos.sh"
            ;;
        fedora|nobara)
            log_info "Using Fedora/Nobara installation script"
            bash "$SCRIPT_DIR/install-fedora.sh"
            ;;
        rocky|rhel|almalinux|centos)
            log_info "Using RHEL-based installation script"
            bash "$SCRIPT_DIR/install-rocky.sh"
            ;;
        ubuntu|debian)
            log_info "Using Debian-based installation script"
            bash "$SCRIPT_DIR/install-debian.sh"
            ;;
        arch|endeavouros|manjaro)
            log_info "Using Arch-based installation script"
            bash "$SCRIPT_DIR/install-arch.sh"
            ;;
        *)
            log_error "Unsupported OS: $OS"
            log_warn "Supported: macOS, Fedora, Nobara, Rocky, RHEL, Ubuntu, Debian, Arch"
            exit 1
            ;;
    esac
    
    # Post-installation configuration
    log_info "Running post-installation configuration..."
    bash "$SCRIPT_DIR/post-install.sh"
    
    log_info "Installation complete! 🎉"
    if [[ "$OS" == "macos" ]]; then
        log_info "You may need to restart your terminal or run: source ~/.zshrc"
    else
        log_info "You may need to restart your shell or run: source ~/.zshrc"
    fi
}

print_logo
main "$@"
