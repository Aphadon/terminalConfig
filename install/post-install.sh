#!/usr/bin/env bash
# post-install.sh - Post-installation configuration and symlinking

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[POST-INSTALL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_prompt() { echo -e "${BLUE}[PROMPT]${NC} $1"; }

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    mkdir -p ~/.config
    mkdir -p ~/.local/share
}

# Setup stow for dotfiles
setup_stow() {
    log_info "Setting up dotfiles with stow..."
    
    cd "$REPO_ROOT"
    
    # List of stow packages to install
    STOW_PACKAGES=(
        "nvim"
        "tmux"
        "yazi"
        "ghostty"
    )
    
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [ -d "$pkg" ]; then
            log_info "Stowing: $pkg"
            stow -v "$pkg" 2>&1 | grep -v "BUG in find_stowed_path" || true
        else
            log_warn "Package directory not found: $pkg"
        fi
    done
}

# Ask user for shell preference
choose_shell() {
    log_info "Shell Configuration"
    echo ""
    log_prompt "Which shell would you like to use?"
    echo "  1) Zsh (with Oh My Zsh)"
    echo "  2) Bash (with Oh My Bash)"
    echo "  3) Skip shell configuration"
    echo ""
    read -p "Enter choice [1-3]: " shell_choice
    
    case "$shell_choice" in
        1)
            SHELL_CHOICE="zsh"
            ;;
        2)
            SHELL_CHOICE="bash"
            ;;
        3)
            SHELL_CHOICE="skip"
            ;;
        *)
            log_warn "Invalid choice, defaulting to Zsh"
            SHELL_CHOICE="zsh"
            ;;
    esac
    
    export SHELL_CHOICE
}

# Setup Zsh as default shell
setup_zsh() {
    if ! command -v zsh &> /dev/null; then
        log_warn "Zsh not installed, skipping Zsh setup"
        return
    fi
    
    log_info "Setting up Zsh..."
    
    # Stow zsh config
    cd "$REPO_ROOT"
    if [ -d "zsh" ]; then
        stow -v zsh 2>&1 | grep -v "BUG in find_stowed_path" || true
    fi
    
    # Install Oh My Zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh My Zsh..."
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
    else
        log_info "Oh My Zsh already installed"
    fi
    
    # Set as default shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        log_info "Setting Zsh as default shell..."
        chsh -s "$(which zsh)" || log_warn "Could not change default shell. You may need to do this manually."
    fi
}

# Setup Bash with Oh My Bash
setup_bash() {
    if ! command -v bash &> /dev/null; then
        log_warn "Bash not installed, skipping Bash setup"
        return
    fi
    
    log_info "Setting up Bash..."
    
    # Stow bash config
    cd "$REPO_ROOT"
    if [ -d "bash" ]; then
        stow -v bash 2>&1 | grep -v "BUG in find_stowed_path" || true
    fi
    
    # Install Oh My Bash if not present
    if [ ! -d "$HOME/.oh-my-bash" ]; then
        log_info "Installing Oh My Bash..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" || true
    else
        log_info "Oh My Bash already installed"
    fi
    
    # Set as default shell
    if [ "$SHELL" != "$(which bash)" ]; then
        log_info "Setting Bash as default shell..."
        chsh -s "$(which bash)" || log_warn "Could not change default shell. You may need to do this manually."
    fi
}

# Install TPM (Tmux Plugin Manager)
install_tpm() {
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$TPM_DIR" ]; then
        log_info "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        log_info "Run 'tmux' and press 'prefix + I' to install tmux plugins"
    else
        log_info "TPM already installed"
    fi
}

# Main post-installation
main() {
    log_info "Starting post-installation configuration..."
    echo ""
    
    create_directories
    setup_stow
    
    # Ask user for shell preference
    choose_shell
    
    case "$SHELL_CHOICE" in
        zsh)
            setup_zsh
            ;;
        bash)
            setup_bash
            ;;
        skip)
            log_info "Skipping shell configuration"
            ;;
    esac
    
    install_tpm
    
    log_info "Post-installation complete!"
    log_info ""
    log_info "Next steps:"
    
    if [ "$SHELL_CHOICE" == "zsh" ]; then
        log_info "  1. Restart your terminal or run: source ~/.zshrc"
    elif [ "$SHELL_CHOICE" == "bash" ]; then
        log_info "  1. Restart your terminal or run: source ~/.bashrc"
    else
        log_info "  1. Restart your terminal"
    fi
    
    log_info "  2. Open tmux and press 'prefix + I' to install plugins"
    log_info "  3. Open Neovim and run :checkhealth"
}

# Allow non-interactive mode via environment variable
if [[ "$SHELL_CHOICE" != "" ]]; then
    # Already set via environment
    main
else
    main
fi
