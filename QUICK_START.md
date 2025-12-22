# Quick Start Guide

## 🚀 Installation (One Command)

```bash
git clone https://github.com/Aphadon/terminalConfig.git && cd terminalConfig/install && ./install.sh
```

## 📋 Choose Your Profile

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

## 🎯 What Gets Installed

### Core Profile (`core`)
- git, curl, wget, stow
- zsh, tmux, fzf
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

## ⚡ Common Commands

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

## 📝 Post-Install

```bash
# 1. Restart terminal or
source ~/.zshrc

# 2. In tmux, install plugins
tmux
# Press: Ctrl+b then Shift+I

# 3. Check neovim
nvim
:checkhealth
```

## 🔧 Quick Customization

```bash
# Add your profile to ~/.install-profile
echo 'export INSTALL_PROFILE="core,dev,desktop"' > ~/.install-profile

# Then just run
./install.sh
```

## 📚 More Info

- [Full Installation Guide](install/README.md)
- [Repository README](README.md)
- [Package Configuration](install/packages.yaml)

## 🆘 Help

```bash
./install.sh --help
```

---

**That's it! Your terminal environment is ready to go.** 🎉
