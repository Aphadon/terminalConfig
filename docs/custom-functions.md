# Custom Installation Functions Guide

Complete guide to writing custom installation functions for complex package installations.

## Overview

Custom functions in `install-functions.sh` handle packages that need:
- Architecture-specific binaries (ARM64 vs x86_64)
- Downloading from GitHub releases
- Building from source
- Platform-specific installation procedures
- Version-specific handling

## When to Use Custom Functions

Use custom functions when:
- ✅ Standard package manager doesn't have the package
- ✅ Package version in repos is outdated
- ✅ Need different binaries for different architectures
- ✅ Raspberry Pi needs ARM64 binaries
- ✅ Building from source is required
- ✅ Installation varies significantly between platforms

Don't use custom functions when:
- ❌ Package is available in standard repos
- ❌ COPR/PPA/AUR is sufficient
- ❌ Installation is identical across platforms

## Function Template

```bash
install_PACKAGENAME() {
    local distro="$1"
    local arch=$(get_arch)
    
    case "$distro" in
        fedora|nobara)
            # Fedora-specific installation
            ;;
        rocky|rhel)
            # Rocky/RHEL-specific installation
            ;;
        debian|ubuntu)
            # Debian/Ubuntu-specific installation
            ;;
        arch|endeavouros|manjaro)
            # Arch-specific installation
            ;;
        macos)
            # macOS-specific installation
            ;;
        *)
            log_error "Unsupported distro for PACKAGENAME: $distro"
            return 1
            ;;
    esac
}
```

## Available Helper Functions

### `get_arch()`

Returns standardized architecture name:

```bash
local arch=$(get_arch)

# Returns:
# - "x86_64" for Intel/AMD 64-bit
# - "arm64" for ARM 64-bit (Raspberry Pi 4, Apple Silicon)
# - "armv7" for ARM 32-bit
# - "unknown" for unsupported architectures
```

**Example:**
```bash
local arch=$(get_arch)
if [[ "$arch" == "arm64" ]]; then
    echo "Running on ARM64 (Raspberry Pi or Apple Silicon)"
fi
```

### `setup_user_bin()`

Creates `~/bin` directory and adds it to PATH:

```bash
setup_user_bin

# Creates ~/bin if it doesn't exist
# Adds ~/bin to PATH in .zshrc and .bashrc
# Exports PATH for current session
```

**Example:**
```bash
setup_user_bin
curl -L "https://releases/binary" -o ~/bin/mybinary
chmod +x ~/bin/mybinary
```

### Logging Functions

```bash
log_info "Information message"    # Green [INFO]
log_warn "Warning message"        # Yellow [WARN]
log_error "Error message"         # Red [ERROR]
```

## Real-World Examples

### Example 1: Neovim (Architecture-Aware)

Downloads ARM64 binary for Raspberry Pi, uses PPA on Ubuntu x86_64:

```bash
install_neovim() {
    local distro="$1"
    local arch=$(get_arch)
    
    case "$distro" in
        fedora|nobara)
            # Fedora usually has recent neovim
            sudo dnf -y install neovim
            ;;
            
        ubuntu|debian)
            if [[ "$arch" == "arm64" ]]; then
                # Raspberry Pi: Download ARM64 binary
                log_info "Installing neovim from GitHub release (ARM64)..."
                setup_user_bin
                
                local nvim_version="v0.11.5"
                local nvim_url="https://github.com/neovim/neovim/releases/download/${nvim_version}/nvim-linux-arm64.tar.gz"
                
                curl -L "$nvim_url" | tar -xz -C /tmp
                mv /tmp/nvim-linux-arm64/bin/nvim "$HOME/bin/"
                chmod +x "$HOME/bin/nvim"
                rm -rf /tmp/nvim-linux-arm64
                
                log_info "Installed neovim to ~/bin/nvim"
            else
                # x86_64: Use PPA for newer version
                log_info "Adding neovim unstable PPA..."
                sudo add-apt-repository -y ppa:neovim-ppa/unstable
                sudo apt-get update
                sudo apt-get install -y neovim
            fi
            ;;
            
        rocky|rhel)
            # Rocky: Build from source or download binary
            setup_user_bin
            local nvim_version="v0.11.5"
            curl -L "https://github.com/neovim/neovim/releases/download/${nvim_version}/nvim-linux64.tar.gz" | tar -xz -C /tmp
            mv /tmp/nvim-linux64/bin/nvim "$HOME/bin/"
            chmod +x "$HOME/bin/nvim"
            rm -rf /tmp/nvim-linux64
            ;;
            
        arch|endeavouros|manjaro)
            sudo pacman -S --needed --noconfirm neovim
            ;;
            
        macos)
            brew install neovim
            ;;
    esac
}
```

### Example 2: LazyGit (GitHub Releases)

Downloads pre-built binaries from GitHub:

```bash
install_lazygit() {
    local distro="$1"
    local arch=$(get_arch)
    
    case "$distro" in
        fedora|nobara)
            # Fedora uses COPR (handled in packages.yaml)
            log_warn "lazygit should use COPR on Fedora"
            sudo dnf -y install lazygit
            ;;
            
        rocky|rhel|debian|ubuntu)
            # Download from GitHub releases
            log_info "Installing lazygit from GitHub releases..."
            setup_user_bin
            
            local version="0.45.1"
            
            # Convert architecture to GitHub release format
            case "$arch" in
                x86_64) gh_arch="x86_64" ;;
                arm64) gh_arch="arm64" ;;
                armv7) gh_arch="armv6" ;;
                *) log_error "Unsupported architecture: $arch"; return 1 ;;
            esac
            
            local url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${gh_arch}.tar.gz"
            
            curl -L "$url" | tar -xz -C /tmp
            mv /tmp/lazygit "$HOME/bin/"
            chmod +x "$HOME/bin/lazygit"
            rm -rf /tmp/lazygit 2>/dev/null || true
            
            log_info "Installed lazygit to ~/bin/lazygit"
            ;;
            
        arch|endeavouros|manjaro)
            sudo pacman -S --needed --noconfirm lazygit
            ;;
            
        macos)
            brew install lazygit
            ;;
    esac
}
```

### Example 3: Building from Source

Compiles package from source with dependencies:

```bash
install_my_tool() {
    local distro="$1"
    
    log_info "Building my_tool from source..."
    
    # Install build dependencies per platform
    case "$distro" in
        fedora|nobara|rocky|rhel)
            sudo dnf -y install gcc make cmake git
            ;;
        debian|ubuntu)
            sudo apt-get install -y build-essential cmake git
            ;;
        arch|endeavouros|manjaro)
            sudo pacman -S --needed --noconfirm base-devel cmake git
            ;;
        macos)
            # Xcode Command Line Tools should be installed
            if ! command -v gcc &> /dev/null; then
                log_error "Xcode Command Line Tools not installed"
                log_info "Run: xcode-select --install"
                return 1
            fi
            ;;
    esac
    
    # Clone and build
    local build_dir="/tmp/my_tool_build"
    rm -rf "$build_dir"
    
    git clone --depth 1 https://github.com/user/my_tool.git "$build_dir"
    cd "$build_dir"
    
    mkdir build && cd build
    cmake ..
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)
    
    # Install to ~/bin for user tools or use sudo make install for system-wide
    setup_user_bin
    cp my_tool "$HOME/bin/"
    chmod +x "$HOME/bin/my_tool"
    
    # Cleanup
    cd /
    rm -rf "$build_dir"
    
    log_info "Built and installed my_tool to ~/bin/my_tool"
}
```

### Example 4: Conditional Installation

Only installs on supported architectures:

```bash
install_docker_desktop() {
    local distro="$1"
    local arch=$(get_arch)
    
    # Docker Desktop only on x86_64
    if [[ "$arch" != "x86_64" ]]; then
        log_warn "Docker Desktop not available for $arch architecture"
        log_info "Consider installing docker.io instead"
        return 1
    fi
    
    case "$distro" in
        ubuntu|debian)
            log_info "Installing Docker Desktop..."
            local deb_file="/tmp/docker-desktop.deb"
            curl -fsSL "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb" -o "$deb_file"
            sudo apt-get install -y "$deb_file"
            rm "$deb_file"
            ;;
            
        fedora|nobara)
            log_info "Installing Docker Desktop..."
            local rpm_file="/tmp/docker-desktop.rpm"
            curl -fsSL "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm" -o "$rpm_file"
            sudo dnf install -y "$rpm_file"
            rm "$rpm_file"
            ;;
            
        *)
            log_error "Docker Desktop installation not supported on $distro"
            return 1
            ;;
    esac
}
```

### Example 5: Installing Multiple Versions (Node.js via nvm)

```bash
install_nodejs() {
    local distro="$1"
    
    log_info "Installing Node.js via nvm..."
    
    # Install nvm if not present
    if [ ! -d "$HOME/.nvm" ]; then
        log_info "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        
        # Load nvm for this session
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        log_info "nvm already installed"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Install LTS version
    log_info "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    
    log_info "Node.js $(node --version) installed via nvm"
}
```

## Step-by-Step Guide

### Step 1: Identify the Need

Determine if you need a custom function:
- Check if package is in standard repos: `dnf search`, `apt search`, `brew search`
- Check if COPR/PPA/AUR is available
- Check if architecture-specific binaries are needed

### Step 2: Add to packages.yaml

```yaml
my-package:
  fedora:
    method: function
  debian:
    method: function
  macos:
    method: brew  # Or function if needed
  tags: [dev, optional]
```

### Step 3: Create Function

Add to `install-functions.sh`:

```bash
install_my_package() {
    local distro="$1"
    local arch=$(get_arch)
    
    # Your installation logic here
}
```

### Step 4: Test on Each Platform

```bash
# Test function directly
source install-functions.sh
install_my_package "fedora"
install_my_package "debian"
```

### Step 5: Run Full Installation

```bash
./install.sh --profile core,dev
```

## Debugging Tips

### Enable Debug Mode

```bash
# At the top of install-functions.sh
set -x  # Show all executed commands

# Or run with debug flag
bash -x install/install.sh
```

### Check Function Exists

```bash
# List all install functions
grep "^install_" install-functions.sh

# Check if specific function exists
declare -f install_neovim
```

### Test Architecture Detection

```bash
# See what get_arch() returns
uname -m

# Test in function
install_test() {
    local arch=$(get_arch)
    echo "Detected architecture: $arch"
}
```

### Verify Downloads

```bash
# Test download URL
curl -I "https://github.com/user/repo/releases/download/v1.0.0/file.tar.gz"

# See full curl output
curl -v -L "https://..." -o /tmp/test
```

## Common Pitfalls

### 1. Function Name Mismatches

```bash
# WRONG: Package name has dash
install_tree-sitter() {  # Invalid bash function name!

# CORRECT: Replace dash with underscore
install_tree_sitter() {
```

### 2. Missing Architecture Handling

```bash
# BAD: Assumes x86_64
curl -L "https://releases/tool-x86_64.tar.gz"

# GOOD: Check architecture
local arch=$(get_arch)
case "$arch" in
    x86_64) url="...x86_64.tar.gz" ;;
    arm64) url="...arm64.tar.gz" ;;
esac
```

### 3. Not Checking if Command Exists

```bash
# BAD: Assumes tool is installed
gcc my_program.c

# GOOD: Check first
if ! command -v gcc &> /dev/null; then
    log_error "gcc not found"
    return 1
fi
```

### 4. Forgetting to Cleanup

```bash
# GOOD: Always cleanup
cd /tmp
git clone ... my_tool
cd my_tool
make install
cd /
rm -rf /tmp/my_tool  # Cleanup!
```

### 5. Hardcoded Paths

```bash
# BAD: Hardcoded home directory
mv binary /home/username/bin/

# GOOD: Use variables
setup_user_bin
mv binary "$HOME/bin/"
```

## Reference

### Common Download Patterns

```bash
# Download and extract tar.gz
curl -L "$url" | tar -xz -C /tmp

# Download and extract zip
curl -L "$url" -o /tmp/file.zip
unzip -q /tmp/file.zip -d /tmp

# Download and gunzip
curl -L "$url" | gunzip -c > ~/bin/tool
chmod +x ~/bin/tool

# Download binary directly
curl -L "$url" -o ~/bin/tool
chmod +x ~/bin/tool
```

### Architecture Mapping

```bash
# Map architecture names for GitHub releases
case "$(get_arch)" in
    x86_64) gh_arch="x86_64" ;;  # or "amd64"
    arm64) gh_arch="aarch64" ;;  # or "arm64"
    armv7) gh_arch="armv7" ;;    # or "arm"
esac
```

### Common Build Patterns

```bash
# CMake build
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install

# Autotools build
./configure --prefix=$HOME/.local
make -j$(nproc)
make install

# Go build
go build -o ~/bin/tool

# Rust build
cargo build --release
cp target/release/tool ~/bin/
```

## Best Practices

1. **Always handle all supported distros** - Use case statement with all platforms
2. **Check architecture when downloading binaries** - Use `get_arch()`
3. **Use setup_user_bin() for user tools** - Installs to ~/bin, adds to PATH
4. **Clean up temporary files** - Remove downloaded files and build directories
5. **Provide informative logs** - Use log_info, log_warn, log_error
6. **Check if already installed** - Use `command -v tool` to avoid reinstalling
7. **Handle errors gracefully** - Return non-zero on errors
8. **Test on actual hardware** - Especially for ARM64 Raspberry Pi

## Further Reading

- [Bash Functions](https://www.gnu.org/software/bash/manual/html_node/Shell-Functions.html)
- [GitHub Releases API](https://docs.github.com/en/rest/releases)
- [CMake Documentation](https://cmake.org/documentation/)
- [GNU Autotools](https://www.gnu.org/software/automake/manual/html_node/Autotools-Introduction.html)
