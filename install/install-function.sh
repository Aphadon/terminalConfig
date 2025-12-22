#!/usr/bin/env bash
# install-functions.sh - Custom installation functions for complex packages
# These functions are called when install_method is "function" in packages.conf

# Detect architecture
get_arch() {
    case "$(uname -m)" in
        x86_64) echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l) echo "armv7" ;;
        *) echo "unknown" ;;
    esac
}

# Ensure ~/bin exists and is in PATH
setup_user_bin() {
    mkdir -p "$HOME/bin"
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        log_info "Adding ~/bin to PATH"
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/bin:$PATH"
    fi
}

# ============================================================================
# LAZYGIT - Terminal UI for git commands
# ============================================================================
install_lazygit() {
    local distro="$1"
    local arch=$(get_arch)
    
    case "$distro" in
        fedora|nobara)
            # This shouldn't be called since Fedora uses COPR
            log_warn "lazygit should use COPR on Fedora"
            sudo dnf -y install lazygit
            ;;
            
        ubuntu|debian|pop|linuxmint)
            # Debian: Install from GitHub releases
            log_info "Installing lazygit from GitHub releases..."
            setup_user_bin
            
            # Get latest release or pin to version
            local version="0.45.1"
            
            case "$arch" in
                x86_64) gh_arch="x86_64" ;;
                arm64) gh_arch="arm64" ;;
                armv7) gh_arch="armv6" ;;
                *) log_error "Unsupported architecture for lazygit: $arch"; return 1 ;;
            esac
            
            local url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${gh_arch}.tar.gz"
            
            log_info "Downloading lazygit v${version}..."
            curl -L "$url" | tar -xz -C /tmp
            mv /tmp/lazygit "$HOME/bin/"
            chmod +x "$HOME/bin/lazygit"
            rm -rf /tmp/lazygit 2>/dev/null || true
            
            log_info "Installed lazygit to ~/bin/lazygit"
            ;;
            
        arch|endeavouros|manjaro)
            # Arch has it in community repo
            log_info "Installing lazygit via pacman..."
            sudo pacman -S --needed --noconfirm lazygit
            ;;
            
        *)
            log_error "Unsupported distro for lazygit: $distro"
            return 1
            ;;
    esac
}

# ============================================================================
# YAZI - Terminal file manager
# ============================================================================
install_yazi() {
    local distro="$1"
    local arch=$(get_arch)
    
    case "$distro" in
        fedora|nobara)
            # This shouldn't be called since Fedora uses COPR
            log_warn "yazi should use COPR on Fedora"
            sudo dnf -y install yazi
            ;;
            
        ubuntu|debian|pop|linuxmint)
            # Debian: Install from GitHub releases
            log_info "Installing yazi from GitHub releases..."
            setup_user_bin
            
            # Get latest release or pin to version
            local version="0.4.2"
            
            case "$arch" in
                x86_64) gh_arch="x86_64-unknown-linux-musl" ;;
                arm64) gh_arch="aarch64-unknown-linux-musl" ;;
                *) log_error "Unsupported architecture for yazi: $arch"; return 1 ;;
            esac
            
            local url="https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-${gh_arch}.zip"
            
            log_info "Downloading yazi v${version}..."
            curl -L "$url" -o /tmp/yazi.zip
            unzip -q /tmp/yazi.zip -d /tmp
            mv /tmp/yazi-${gh_arch}/yazi "$HOME/bin/"
            chmod +x "$HOME/bin/yazi"
            rm -rf /tmp/yazi.zip /tmp/yazi-${gh_arch}
            
            log_info "Installed yazi to ~/bin/yazi"
            ;;
            
        arch|endeavouros|manjaro)
            # Arch has it in community repo
            log_info "Installing yazi via pacman..."
            sudo pacman -S --needed --noconfirm yazi
            ;;
            
        *)
            log_error "Unsupported distro for yazi: $distro"
            return 1
            ;;
    esac
}

# ============================================================================
# NEOVIM - Handle version and architecture differences
# ============================================================================
install_neovim() {
    local distro="$1"
    local arch=$(get_arch)
    
    case "$distro" in
        fedora|nobara)
            # Fedora usually has recent neovim
            log_info "Installing neovim via DNF..."
            sudo dnf -y install neovim
            ;;
            
        ubuntu|debian|pop|linuxmint)
            # Check if we're on ARM (Raspberry Pi, etc.)
            if [[ "$arch" == "arm64" ]]; then
                log_info "Installing neovim from GitHub release (ARM64)..."
                setup_user_bin
                
                local nvim_version="v0.11.5"
                local nvim_url="https://github.com/neovim/neovim/releases/download/${nvim_version}/nvim-linux-arm64.tar.gz"
                
                log_info "Downloading neovim ${nvim_version}..."
                curl -L "$nvim_url" | tar -xz -C /tmp
                
                # Move to ~/bin or /usr/local/bin
                if [ -w /usr/local/bin ]; then
                    sudo mv /tmp/nvim-linux-arm64/bin/nvim /usr/local/bin/
                    sudo chmod +x /usr/local/bin/nvim
                    log_info "Installed to /usr/local/bin/nvim"
                else
                    mv /tmp/nvim-linux-arm64/bin/nvim "$HOME/bin/"
                    chmod +x "$HOME/bin/nvim"
                    log_info "Installed to ~/bin/nvim"
                fi
                
                rm -rf /tmp/nvim-linux-arm64
            else
                # Try to use PPA for newer version on x86_64
                log_info "Adding neovim unstable PPA..."
                sudo add-apt-repository -y ppa:neovim-ppa/unstable
                sudo apt-get update
                sudo apt-get install -y neovim
            fi
            ;;
            
        arch|endeavouros|manjaro)
            # Arch usually has latest neovim
            log_info "Installing neovim via pacman..."
            sudo pacman -S --needed --noconfirm neovim
            ;;
            
        *)
            log_error "Unsupported distro for neovim custom install: $distro"
            return 1
            ;;
    esac
}

# ============================================================================
# TREE-SITTER - CLI tool for parsing
# ============================================================================
install_tree-sitter() {
    local distro="$1"
    local arch=$(get_arch)
    
    case "$distro" in
        fedora|nobara|ubuntu|debian|pop|linuxmint)
            if [[ "$arch" == "arm64" ]]; then
                log_info "Installing tree-sitter from GitHub release (ARM64)..."
                setup_user_bin
                
                local ts_version="v0.25.1"
                local ts_url="https://github.com/tree-sitter/tree-sitter/releases/download/${ts_version}/tree-sitter-linux-arm64.gz"
                
                log_info "Downloading tree-sitter ${ts_version}..."
                curl -L "$ts_url" | gunzip -c > "$HOME/bin/tree-sitter"
                chmod +x "$HOME/bin/tree-sitter"
                log_info "Installed tree-sitter to ~/bin/tree-sitter"
            else
                log_info "Installing tree-sitter from GitHub release (x86_64)..."
                setup_user_bin
                
                local ts_version="v0.25.1"
                local ts_url="https://github.com/tree-sitter/tree-sitter/releases/download/${ts_version}/tree-sitter-linux-x86_64.gz"
                
                curl -L "$ts_url" | gunzip -c > "$HOME/bin/tree-sitter"
                chmod +x "$HOME/bin/tree-sitter"
                log_info "Installed tree-sitter to ~/bin/tree-sitter"
            fi
            ;;
            
        arch|endeavouros|manjaro)
            log_info "Installing tree-sitter via pacman..."
            sudo pacman -S --needed --noconfirm tree-sitter
            ;;
            
        *)
            log_error "Unsupported distro for tree-sitter custom install: $distro"
            return 1
            ;;
    esac
}

# ============================================================================
# TEMPLATE - Copy this for new custom installations
# ============================================================================
# install_PACKAGENAME() {
#     local distro="$1"
#     local arch=$(get_arch)
#     
#     case "$distro" in
#         fedora|nobara)
#             # Fedora-specific installation
#             ;;
#         ubuntu|debian|pop|linuxmint)
#             # Debian-specific installation
#             ;;
#         arch|endeavouros|manjaro)
#             # Arch-specific installation
#             ;;
#         *)
#             log_error "Unsupported distro: $distro"
#             return 1
#             ;;
#     esac
# }

# ============================================================================
# EXAMPLE: Install from source with make
# ============================================================================
# install_fromsource() {
#     local distro="$1"
#     
#     log_info "Building fromsource from source..."
#     
#     # Install build dependencies
#     case "$distro" in
#         fedora|nobara)
#             sudo dnf -y install gcc make automake
#             ;;
#         ubuntu|debian|pop|linuxmint)
#             sudo apt-get install -y build-essential
#             ;;
#         arch|endeavouros|manjaro)
#             sudo pacman -S --needed --noconfirm base-devel
#             ;;
#     esac
#     
#     # Clone and build
#     cd /tmp
#     git clone https://github.com/user/repo.git
#     cd repo
#     make
#     sudo make install
#     cd -
#     rm -rf /tmp/repo
# }
