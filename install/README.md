# Installation System

Multi-platform dotfiles installation system with profile-based package management.

## Quick Start

```bash
# Clone the repo
git clone https://github.com/Aphadon/terminalConfig.git
cd terminalConfig/install

# Install everything
./install.sh

# Or install with a specific profile
./install.sh --profile core,dev,desktop
```

## Supported Platforms

- **macOS** (Homebrew)
- **Fedora / Nobara** (DNF + COPR)
- **Rocky Linux / RHEL / AlmaLinux** (DNF + EPEL)
- **Debian** (APT + custom binaries)
- **Ubuntu** (APT + PPAs)
- **Arch Linux** (Pacman + AUR)

## Installation Profiles

### Common Profiles

```bash
# Full installation (everything)
./install.sh

# Minimal (core tools only)
./install.sh --profile core

# Development workstation
./install.sh --profile core,dev,desktop

# Server (no GUI)
./install.sh --profile core,server

# Headless machine
./install.sh --profile core,dev --exclude gui
```

### Profile Tags

| Tag | Description | Packages |
|-----|-------------|----------|
| `core` | Essential utilities | git, curl, wget, tmux, neovim, yazi |
| `dev` | Development tools | lazygit, ripgrep, fd, bat, eza, delta |
| `desktop` | Desktop applications | ghostty |
| `gui` | GUI applications | Anything requiring display server |
| `server` | Server tools | docker, nginx, etc. |
| `optional` | Nice-to-have | btop, ffmpegthumbnailer |

## Package Management

### Adding New Packages

Edit `packages.yaml`:

```yaml
my-package:
  fedora: my-package
  debian: my-package
  macos:
    method: brew
  tags: [dev, optional]
```

### Package Configuration Format

```yaml
package-name:
  # Simple: same name on all distros
  default: package-name

  # Or per-distro configuration
  fedora: fedora-package-name
  debian: debian-package-name
  macos:
    package: macos-package-name
    method: brew

  # Installation method (if not standard)
  fedora:
    package: package-name
    method: copr:user/repo

  # Tags for profile filtering
  tags: [core, dev]
```

### Installation Methods

| Method | Description | Platform |
|--------|-------------|----------|
| (default) | Standard package manager | All |
| `brew` | Homebrew | macOS |
| `copr:user/repo` | COPR repository | Fedora, Rocky |
| `ppa:user/repo` | PPA repository | Ubuntu |
| `aur` | Arch User Repository | Arch |
| `function` | Custom install function | All |
| `skip: true` | Skip on this platform | All |

## Custom Installation Functions

For complex installations (architecture-specific, GitHub releases, building from source), use custom functions in `install-functions.sh`:

```bash
install_my_package() {
    local distro="$1"
    local arch=$(get_arch)

    case "$distro" in
        fedora|rocky)
            sudo dnf install -y my-package
            ;;
        debian|ubuntu)
            if [[ "$arch" == "arm64" ]]; then
                # Download ARM64 binary from GitHub
                curl -L "https://releases/my-package-arm64" -o ~/bin/my-package
            else
                sudo apt-get install -y my-package
            fi
            ;;
        macos)
            brew install my-package
            ;;
    esac
}
```

### Helper Functions

- `get_arch()` - Returns: `x86_64`, `arm64`, `armv7`, or `unknown`
- `setup_user_bin()` - Creates `~/bin` and adds to PATH
- `log_info()`, `log_warn()`, `log_error()` - Colored logging

## File Structure

```
install/
├── install.sh              # Main entry point
├── install-macos.sh        # macOS (Homebrew)
├── install-fedora.sh       # Fedora / Nobara
├── install-rocky.sh        # Rocky / RHEL
├── install-debian.sh       # Debian / Ubuntu
├── install-arch.sh         # Arch Linux
├── install-functions.sh    # Custom installation functions
├── post-install.sh         # Post-install tasks (stow, etc.)
├── packages.yaml           # Package definitions
└── README.md               # This file
```

## Usage Examples

### Fedora Desktop

```bash
./install.sh --profile core,dev,desktop
```

Installs: Core tools + dev tools + GUI apps (ghostty)

### Rocky Linux Server

```bash
./install.sh --profile core,server
```

Installs: Core tools + server tools (docker), skips GUI

### Raspberry Pi (Headless)

```bash
./install.sh --profile core,dev --exclude gui
```

Installs: Core tools (ARM64 binaries) + dev tools, skips GUI

### macOS Laptop

```bash
./install.sh --profile core,dev,desktop
```

Installs: Everything via Homebrew

## Advanced Usage

### Command Line Options

```bash
./install.sh [OPTIONS]

Options:
  --profile <tags>    Install packages with specific tags (comma-separated)
  --exclude <tags>    Exclude packages with specific tags
  --help              Show help message
```

### Examples

```bash
# Core + dev tools, skip optional packages
./install.sh --profile core,dev --exclude optional

# Everything except GUI applications
./install.sh --exclude gui

# Only essential tools
./install.sh --profile core
```

### Per-Machine Configuration

Create `~/.install-profile` on each machine:

```bash
# ~/.install-profile
export INSTALL_PROFILE="core,dev,desktop"
export EXCLUDE_TAGS="optional"
```

Modify `install.sh` to source it:

```bash
if [ -f ~/.install-profile ]; then
    source ~/.install-profile
fi
```

## Troubleshooting

### yq Not Found

The scripts automatically install `yq` (YAML parser). If it fails:

```bash
# Manual installation
# Fedora/Rocky
sudo dnf install yq

# Debian/Ubuntu (downloads from GitHub, no snap)
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# macOS
brew install yq

# Arch
sudo pacman -S go-yq
```

### Package Not Installing

1. **Check if it's being filtered:**
   ```bash
   # See what's being skipped
   ./install.sh --profile core 2>&1 | grep "Excluding\|Skipping"
   ```

2. **Verify package name:**
   ```bash
   # Fedora
   dnf search package-name

   # Debian/Ubuntu
   apt search package-name

   # macOS
   brew search package-name
   ```

3. **Check YAML syntax:**
   ```bash
   yq eval packages.yaml
   ```

### COPR/PPA Fails

- Verify the repository exists for your distro version
- Check if repository supports your architecture (ARM64 vs x86_64)
- Consider using custom function with GitHub releases instead

### Architecture Detection Issues

```bash
# Check detected architecture
uname -m

# x86_64 = Intel/AMD 64-bit
# aarch64 = ARM 64-bit (Raspberry Pi 4, Apple Silicon)
# armv7l = ARM 32-bit
```

## Documentation

- [Custom Functions Guide](../docs/custom-functions.md) - Writing custom installation functions
- [Package Configuration](../docs/package-config.md) - YAML format reference
- [Profile System](../docs/profiles.md) - Tag-based installation profiles

## Contributing

### Adding New Platform

1. Create `install-yourplatform.sh` based on existing scripts
2. Add platform detection to `install.sh`
3. Update `packages.yaml` with platform-specific packages
4. Test on the target platform

### Adding New Package

1. Add to `packages.yaml` with appropriate tags
2. If complex installation needed, add function to `install-functions.sh`
3. Test on at least one platform per distro family

## Design Decisions

### Why YAML instead of shell config?

- **Readable**: Clear structure, easy to understand
- **Scalable**: Add platforms without breaking existing config
- **Flexible**: Each platform can have completely different configuration
- **Validated**: YAML parsers catch syntax errors

### Why profile/tag system?

- **One config, many machines**: Same repo for desktop, server, Raspberry Pi
- **Fine-grained control**: Install exactly what you need
- **No duplication**: Don't maintain separate package lists per machine

### Why no snap on Debian/Ubuntu?

- User preference (configurable)
- Snaps can be slower and have sandboxing issues
- Direct binary downloads or PPAs provide better control

## Related

- [Main Repository README](../README.md)
- [Neovim Configuration](../nvim/)
- [Tmux Configuration](../tmux/)
- [Zsh Configuration](../zsh/)

## License

MIT - See [LICENSE](../LICENSE)
