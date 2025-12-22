# Quick Start Guide

## Installation (One Command)

```bash
git clone https://github.com/Aphadon/terminalConfig.git && cd terminalConfig/install && ./install.sh
```

## 🐚 Shell Selection

During installation, you'll be prompted to choose your shell:
1. **Zsh** (with Oh My Zsh) - Modern, feature-rich
2. **Bash** (with Oh My Bash) - Universal, compatible
3. **Skip** - Configure later

Choose based on your preference - both work great!

## Choose Your Profile

### Fedora Desktop
```bash
./install.sh --profile core,dev,desktop
```

### Rocky Linux Server
```bash
./install.sh --profile core,server
```

### Raspberry Pi (Headless)
```bash
./install.sh --profile core,dev --exclude gui
```

### Debian x86_64 Desktop
```bash
./install.sh --profile core,dev,desktop
```

### Ubuntu Laptop
```bash
./install.sh --profile core,dev,desktop
```

### macOS Laptop
```bash
./install.sh --profile core,dev,desktop
```

## What Gets Installed

### Core Profile (`core`)
- git, curl, wget, stow
- bash, zsh (choose during install), tmux, fzf
- neovim, yazi
- jq, tree, htop

### Dev Profile (`dev`)
- lazygit
- ripgrep, fd, bat, eza, delta
- tree-sitter

### Desktop Profile (`desktop`)
- ghostty

### Server Profile (`server`)
- docker, docker-compose (if uncommented)

## Common Commands

```bash
# Full installation
./install.sh

# Minimal
./install.sh --profile core

# No GUI apps
./install.sh --exclude gui

# Get help
./install.sh --help
```

## Post-Install

```bash
# 1. During installation, choose your shell:
#    - Option 1: Zsh (with Oh My Zsh)
#    - Option 2: Bash (with Oh My Bash)
#    - Option 3: Skip

# 2. Restart terminal or source your config
# If you chose Zsh:
source ~/.zshrc

# If you chose Bash:
source ~/.bashrc

# 3. In tmux, install plugins
tmux
# Press: Ctrl+b then Shift+I

# 4. Check neovim
nvim
:checkhealth
```

## Quick Customization

```bash
# Add your profile to ~/.install-profile
echo 'export INSTALL_PROFILE="core,dev,desktop"' > ~/.install-profile

# Then just run
./install.sh
```

## Switch Shells Later

You can always switch between Bash and Zsh:

```bash
# Switch to Zsh
chsh -s $(which zsh)

# Switch to Bash
chsh -s $(which bash)

# Log out and back in for changes to take effect
```

## More Info

- [Full Installation Guide](install/README.md)
- [Repository README](README.md)
- [Bash vs Zsh Guide](docs/bash-vs-zsh.md)
- [Package Configuration](install/packages.yaml)
- [Complete Documentation](docs/README.md)

## Help

```bash
./install.sh --help
```

---

**That's it! Your terminal environment is ready to go.** 🎉

**Shell choice:** Bash for compatibility, Zsh for features - both work great!

