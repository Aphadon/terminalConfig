# Terminal Configuration

Personal dotfiles and terminal configuration for multi-platform development environments.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/Aphadon/terminalConfig.git
cd terminalConfig

# Install packages and configure
cd install
./install.sh --profile core,dev,desktop
```

## What's Included

### Core Applications

- **Neovim** - Modern terminal-based text editor with LSP support
- **Tmux** - Terminal multiplexer for managing multiple sessions
- **Bash / Zsh** - Advanced shells with Oh My Bash / Oh My Zsh
- **Yazi** - Modern terminal file manager
- **Ghostty** - Fast, feature-rich terminal emulator (desktop only)

### Development Tools

- **LazyGit** - Terminal UI for git commands
- **Ripgrep** - Fast recursive search tool
- **fd** - User-friendly alternative to find
- **bat** - Cat clone with syntax highlighting
- **eza** - Modern replacement for ls
- **delta** - Syntax-highlighting pager for git

## Supported Platforms

- ✅ **macOS** (Homebrew)
- ✅ **Fedora / Nobara** (DNF + COPR)
- ✅ **Rocky Linux / RHEL** (DNF + EPEL)
- ✅ **Debian** (APT + custom binaries, ARM64 support)
- ✅ **Ubuntu** (APT + PPAs)
- ✅ **Arch Linux** (Pacman + AUR)

### Architecture Support

- ✅ **x86_64** (Intel/AMD 64-bit)
- ✅ **ARM64** (Raspberry Pi 4, Apple Silicon)
- ✅ **ARMv7** (Raspberry Pi 3, older ARM devices)

## Repository Structure

```
terminalConfig/
├── install/                 # Installation system
│   ├── install.sh          # Main installer with profile support
│   ├── install-*.sh        # Platform-specific installers
│   ├── packages.yaml       # Package definitions
│   └── README.md           # Installation documentation
├── nvim/                    # Neovim configuration
│   └── .config/nvim/       
├── tmux/                    # Tmux configuration
│   └── .tmux.conf
├── bash/                    # Bash configuration (optional)
│   └── .bashrc
├── zsh/                     # Zsh configuration (optional)
│   ├── .zshrc
│   └── .zsh/
├── yazi/                    # Yazi file manager config
│   └── .config/yazi/
├── ghostty/                 # Ghostty terminal config
│   └── .config/ghostty/
├── aerospace/               # Aerospace (macOS window manager)
│   └── .config/aerospace/
└── docs/                    # Additional documentation
    ├── custom-functions.md  # Writing custom installation functions
    ├── package-config.md    # YAML configuration reference
    └── profiles.md          # Profile system guide
```

## Installation Profiles

The installation system supports profile-based installations for different machine types:

### Desktop/Laptop

```bash
./install.sh --profile core,dev,desktop
```

Installs everything including GUI applications (ghostty, etc.)

### Server

```bash
./install.sh --profile core,server
```

Essential tools + server utilities, no GUI applications

### Headless (Raspberry Pi)

```bash
./install.sh --profile core,dev --exclude gui
```

Core tools + development utilities, GUI applications excluded

### Minimal

```bash
./install.sh --profile core
```

Only essential utilities (git, curl, tmux, neovim, yazi)

## Configuration Details

### Neovim

- Modern LSP-based configuration
- Custom keybindings for efficient workflow
- Plugin management with lazy.nvim
- Support for multiple languages

**Location:** `nvim/.config/nvim/`

### Tmux

- Custom keybindings with prefix `Ctrl+b`
- TPM (Tmux Plugin Manager) integration
- Status bar customization
- Session management

**Location:** `tmux/.tmux.conf`

### Bash / Zsh

During installation, you'll be prompted to choose between Bash or Zsh:
- **Bash** with Oh My Bash framework
- **Zsh** with Oh My Zsh framework
- Custom aliases and functions
- Enhanced history search
- Git integration

**Location:** `bash/.bashrc` or `zsh/.zshrc`, `zsh/.zsh/`

### Yazi

- Modern terminal file manager
- Image previews (with ffmpegthumbnailer)
- Custom keybindings
- Integration with other tools

**Location:** `yazi/.config/yazi/`

### Ghostty

- Fast GPU-accelerated terminal emulator
- Custom theme and keybindings
- Shell integration
- Desktop-only (not installed on servers)

**Location:** `ghostty/.config/ghostty/`

## Documentation

- **[Installation Guide](install/README.md)** - Detailed installation instructions and troubleshooting
- **[Quick Start](QUICK_START.md)** - One-page reference for getting started
- **[Custom Functions](docs/custom-functions.md)** - Writing custom package installation functions
- **[Package Configuration](docs/package-config.md)** - YAML configuration reference
- **[Profile System](docs/profiles.md)** - Tag-based installation profiles

## Post-Installation

After running the installer:

1. **Choose your shell** during post-installation:
   - Option 1: Zsh with Oh My Zsh
   - Option 2: Bash with Oh My Bash
   - Option 3: Skip shell configuration

2. **Restart your terminal** or source your shell config:
   ```bash
   # If you chose Zsh
   source ~/.zshrc
   
   # If you chose Bash
   source ~/.bashrc
   ```

3. **Install Tmux plugins:**
   ```bash
   tmux
   # Press prefix + I (Ctrl+b then Shift+I)
   ```

4. **Check Neovim setup:**
   ```bash
   nvim
   :checkhealth
   ```

## Customization

### Machine-Specific Configuration

Create `~/.install-profile` on each machine:

```bash
# Desktop
export INSTALL_PROFILE="core,dev,desktop"

# Server
export INSTALL_PROFILE="core,server"
export EXCLUDE_TAGS="gui"
```

### Add Custom Packages

Edit `install/packages.yaml`:

```yaml
my-package:
  fedora: my-package
  debian: my-package
  macos:
    method: brew
  tags: [dev, optional]
```

### Override Configurations

Local overrides won't be committed (add to `.gitignore` if needed):

```bash
# Local Neovim config
~/.config/nvim/lua/local-config.lua

# Local Zsh config
~/.zshrc.local
```

## Usage Examples

### Using Tmux

```bash
# Start new session
tmux

# Create new window: prefix + c (Ctrl+b, then c)
# Switch windows: prefix + number
# Split panes: prefix + " (horizontal) or prefix + % (vertical)
# Detach: prefix + d
```

### Using Yazi

```bash
# Launch file manager
yazi

# Navigation: arrow keys or hjkl
# Open file: Enter
# Back: Backspace
# Quit: q
```

### Using LazyGit

```bash
# Launch in git repository
lazygit

# Stage files: space
# Commit: c
# Push: P
# Pull: p
```

## Troubleshooting

### Installation Issues

See [Installation Guide](install/README.md) for detailed troubleshooting.

Common issues:
- **yq not found** - Installer will download it automatically
- **COPR/PPA fails** - Check repository compatibility with your distro version
- **ARM binary issues** - Verify your architecture with `uname -m`

### Neovim Issues

```bash
# Check health
nvim
:checkhealth

# Update plugins
:Lazy update

# Clear cache
rm -rf ~/.local/share/nvim
```

### Tmux Plugin Issues

```bash
# Reinstall TPM
rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install plugins
# In tmux: prefix + I
```

### Zsh Issues

```bash
# Reinstall Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Reset to default
cp ~/.zshrc.pre-oh-my-zsh ~/.zshrc
```

### Bash Issues

```bash
# Reinstall Oh My Bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Reset to default
cp ~/.bashrc.pre-oh-my-bash ~/.bashrc
```

## Updates

### Updating Dotfiles

```bash
cd terminalConfig
git pull origin main

# Reinstall (respects existing configs)
cd install
./install.sh --profile core,dev,desktop
```

### Updating Individual Configs

```bash
# Re-stow specific config
cd terminalConfig
stow -R nvim  # or tmux, zsh, yazi, etc.
```

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on your platform
5. Submit a pull request

## Design Philosophy

- **Multi-platform first** - Same config works everywhere
- **Profile-based** - Install what you need, skip what you don't
- **Architecture-aware** - Handles x86_64, ARM64, ARMv7
- **Minimal dependencies** - Core tools work everywhere
- **Extensible** - Easy to add new packages and platforms
- **No snap** - Direct binaries and native package managers

## Use Cases

### Development Workstation

Full development environment with GUI tools:

```bash
./install.sh --profile core,dev,desktop
```

### Cloud Server

Minimal, efficient server setup:

```bash
./install.sh --profile core,server
```

### Raspberry Pi

Headless development environment:

```bash
./install.sh --profile core,dev --exclude gui
```

### Multiple Machines

Same repo, different profiles per machine type. One `git pull` updates all configs.

## Learning Resources

- [Neovim Documentation](https://neovim.io/doc/)
- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Yazi Documentation](https://yazi-rs.github.io/)
- [LazyGit Documentation](https://github.com/jesseduffield/lazygit)

## Acknowledgments

- Built with inspiration from the dotfiles community
- Uses excellent tools: Neovim, Tmux, Oh My Zsh, Yazi, LazyGit
- Thanks to all open-source maintainers

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Links

- [Issues](https://github.com/Aphadon/terminalConfig/issues)
- [Pull Requests](https://github.com/Aphadon/terminalConfig/pulls)
- [Discussions](https://github.com/Aphadon/terminalConfig/discussions)

---

**Made with ❤️ for terminal enthusiasts**

*Works on Fedora, Rocky, Debian (Raspberry Pi & x86_64), Ubuntu, macOS, and Arch Linux*
