# Profile System Guide

Complete guide to the tag-based profile system for controlling package installation.

## Overview

The profile system lets you install different sets of packages on different machines using the same configuration repository.

**One repo, many machines:**
- Desktop: Full installation with GUI apps
- Server: Essential tools + server utilities, no GUI
- Headless: Development tools without display server
- Minimal: Just the essentials

## How It Works

### Tags

Each package in `packages.yaml` has tags:

```yaml
neovim:
  default: neovim
  tags: [core]  # ← Installs with 'core' profile

lazygit:
  default: lazygit
  tags: [dev]  # ← Installs with 'dev' profile

ghostty:
  method: brew
  tags: [desktop, gui]  # ← Installs with 'desktop' profile
```

### Profiles

Run installer with specific profile tags:

```bash
# Install only core packages
./install.sh --profile core

# Install core + dev packages
./install.sh --profile core,dev

# Install core + dev + desktop packages
./install.sh --profile core,dev,desktop
```

### Exclusions

Exclude specific tag categories:

```bash
# Install everything except GUI apps
./install.sh --exclude gui

# Install core + dev, skip optional packages
./install.sh --profile core,dev --exclude optional
```

## Available Tags

| Tag | Purpose | When to Use |
|-----|---------|-------------|
| **core** | Essential utilities | Every machine |
| **dev** | Development tools | Development machines |
| **desktop** | Desktop applications | Machines with GUI |
| **gui** | GUI applications | Machines with display server |
| **server** | Server-specific tools | Server machines |
| **optional** | Nice-to-have packages | When you want extras |

## Tag Definitions

### Core (`core`)

**Purpose:** Essential command-line utilities needed on every machine.

**Packages:**
- git, curl, wget, stow
- bash, zsh, tmux, fzf
- neovim, yazi
- jq, tree, htop

**When to use:** Always. Every profile should include `core`.

```bash
# Minimal installation
./install.sh --profile core
```

### Dev (`dev`)

**Purpose:** Development and productivity tools.

**Packages:**
- lazygit (git TUI)
- ripgrep (fast search)
- fd (find alternative)
- bat (cat with syntax highlighting)
- eza (modern ls)
- delta (git diff pager)
- tree-sitter (parsing tool)

**When to use:** Development workstations, machines where you code.

```bash
# Development machine
./install.sh --profile core,dev
```

### Desktop (`desktop`)

**Purpose:** Desktop-specific applications.

**Packages:**
- ghostty (terminal emulator)
- aerospace (macOS window manager)
- Other desktop applications

**When to use:** Machines with desktop environment.

```bash
# Desktop/laptop
./install.sh --profile core,dev,desktop
```

### GUI (`gui`)

**Purpose:** Applications requiring display server.

**Packages:**
- Any application that needs X11/Wayland/macOS display
- ghostty, browsers, GUI editors, etc.

**When to use:** Tag GUI apps so they can be excluded on headless servers.

```bash
# Headless server
./install.sh --exclude gui
```

### Server (`server`)

**Purpose:** Server-specific tools and services.

**Packages:**
- docker, docker-compose
- nginx, apache
- postgresql, redis
- monitoring tools

**When to use:** Server installations.

```bash
# Server setup
./install.sh --profile core,server
```

### Optional (`optional`)

**Purpose:** Nice-to-have but not essential packages.

**Packages:**
- btop (system monitor)
- ffmpegthumbnailer (video thumbnails)
- Additional utilities

**When to use:** When you want extras beyond core functionality.

```bash
# Full installation with optional packages
./install.sh --profile core,dev,optional

# Without optional packages
./install.sh --profile core,dev --exclude optional
```

## Common Profiles

### Minimal

```bash
./install.sh --profile core
```

**Installs:**
- git, curl, wget
- bash, zsh, tmux
- neovim, yazi
- jq, tree, htop

**Use for:** Minimal servers, testing, constrained environments.

### Development Workstation

```bash
./install.sh --profile core,dev,desktop
```

**Installs:**
- Everything from core
- lazygit, ripgrep, fd, bat, eza
- ghostty, desktop apps

**Use for:** Developer laptops and desktops.

### Server

```bash
./install.sh --profile core,server
```

**Installs:**
- Everything from core
- docker, server tools
- No GUI applications

**Use for:** Production servers, VPS, cloud instances.

### Headless (Raspberry Pi)

```bash
./install.sh --profile core,dev --exclude gui
```

**Installs:**
- Everything from core
- Development tools
- Explicitly excludes GUI apps

**Use for:** Raspberry Pi, headless servers with dev tools.

### Full Installation

```bash
./install.sh
# Or explicitly:
./install.sh --profile full
```

**Installs:** Everything (default behavior).

**Use for:** Main development machine, want everything available.

## Command Reference

### Basic Usage

```bash
# Show help
./install.sh --help

# Install with profile
./install.sh --profile <tags>

# Exclude tags
./install.sh --exclude <tags>

# Combine profile and exclusion
./install.sh --profile core,dev --exclude optional
```

### Profile Syntax

```bash
# Single tag
./install.sh --profile core

# Multiple tags (comma-separated, no spaces)
./install.sh --profile core,dev,desktop

# Full installation (default)
./install.sh
./install.sh --profile full
```

### Exclusion Syntax

```bash
# Exclude single tag
./install.sh --exclude gui

# Exclude multiple tags
./install.sh --exclude gui,optional

# Combine with profile
./install.sh --profile core,dev,desktop --exclude optional
```

## Per-Machine Setup

### Option 1: Command Line Arguments

Run with appropriate flags on each machine:

```bash
# Fedora Desktop
./install.sh --profile core,dev,desktop

# Rocky Server
./install.sh --profile core,server

# Raspberry Pi
./install.sh --profile core,dev --exclude gui
```

### Option 2: Environment Variables

Set environment variables before running:

```bash
# Set for current session
export INSTALL_PROFILE="core,dev,desktop"
export EXCLUDE_TAGS="optional"
./install.sh

# Or inline
INSTALL_PROFILE="core,server" ./install.sh
```

### Option 3: Profile Configuration File

Create `~/.install-profile` on each machine:

```bash
# Fedora Desktop: ~/.install-profile
export INSTALL_PROFILE="core,dev,desktop"

# Rocky Server: ~/.install-profile
export INSTALL_PROFILE="core,server"
export EXCLUDE_TAGS="gui"

# Raspberry Pi: ~/.install-profile
export INSTALL_PROFILE="core,dev"
export EXCLUDE_TAGS="gui,optional"
```

Modify `install.sh` to source it:

```bash
# Add to install.sh before parsing arguments
if [ -f ~/.install-profile ]; then
    source ~/.install-profile
fi
```

Then just run: `./install.sh`

### Option 4: Hostname-Based Auto-Detection

Add to `install.sh`:

```bash
# Auto-detect profile based on hostname
case "$(hostname)" in
    *-desktop|*-laptop)
        INSTALL_PROFILE="${INSTALL_PROFILE:-core,dev,desktop}"
        ;;
    *-server|*-vps)
        INSTALL_PROFILE="${INSTALL_PROFILE:-core,server}"
        EXCLUDE_TAGS="${EXCLUDE_TAGS:-gui}"
        ;;
    raspberrypi*)
        INSTALL_PROFILE="${INSTALL_PROFILE:-core,dev}"
        EXCLUDE_TAGS="${EXCLUDE_TAGS:-gui}"
        ;;
esac
```

## Profile Matrix

| Machine Type | Profile Command | Core | Dev | Desktop | GUI | Server |
|--------------|----------------|------|-----|---------|-----|--------|
| **Fedora Desktop** | `--profile core,dev,desktop` | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Rocky Server** | `--profile core,server` | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Raspberry Pi** | `--profile core,dev --exclude gui` | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Debian x86_64 Desktop** | `--profile core,dev,desktop` | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Ubuntu Laptop** | `--profile core,dev,desktop` | ✅ | ✅ | ✅ | ✅ | ❌ |
| **macOS Laptop** | `--profile core,dev,desktop` | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Minimal Server** | `--profile core` | ✅ | ❌ | ❌ | ❌ | ❌ |

## Real-World Scenarios

### Scenario 1: New Development Laptop

```bash
git clone https://github.com/Aphadon/terminalConfig.git
cd terminalConfig/install
./install.sh --profile core,dev,desktop
```

Gets: All development tools + GUI applications.

### Scenario 2: Cloud Server Setup

```bash
git clone https://github.com/Aphadon/terminalConfig.git
cd terminalConfig/install
./install.sh --profile core,server
```

Gets: Essential tools + docker, no GUI overhead.

### Scenario 3: Raspberry Pi Home Server

```bash
git clone https://github.com/Aphadon/terminalConfig.git
cd terminalConfig/install
./install.sh --profile core,dev --exclude gui
```

Gets: Core tools + dev tools (ARM64 binaries), no GUI apps.

### Scenario 4: Minimal Testing Environment

```bash
./install.sh --profile core
```

Gets: Just the essentials for quick testing.

### Scenario 5: Desktop Without Optional Bloat

```bash
./install.sh --profile core,dev,desktop --exclude optional
```

Gets: Full desktop setup but skips optional packages like btop.

## Debugging Profiles

### See What Would Install

Check which packages match your profile:

```bash
# Core packages
yq eval '.packages | to_entries | .[] | select(.value.tags[] == "core") | .key' install/packages.yaml

# Dev packages
yq eval '.packages | to_entries | .[] | select(.value.tags[] == "dev") | .key' install/packages.yaml
```

### Test Profile Filtering

Run with verbose output:

```bash
./install.sh --profile core 2>&1 | grep -E "Installing:|Skipping:"
```

### Verify Tag Assignments

Check specific package tags:

```bash
# Check neovim tags
yq eval '.packages.neovim.tags' install/packages.yaml

# Check all packages with 'core' tag
yq eval '.packages | to_entries | .[] | select(.value.tags[] == "core") | .key' install/packages.yaml
```

## Tips and Best Practices

### 1. Always Include Core

```bash
# GOOD: Core is always included
./install.sh --profile core,dev

# BAD: No core, missing essential tools
./install.sh --profile dev
```

### 2. Use Exclusions for Edge Cases

```bash
# Raspberry Pi: Has core and dev, but no GUI
./install.sh --profile core,dev --exclude gui
```

### 3. Test Before Deployment

```bash
# Test on development machine first
./install.sh --profile core,dev,desktop

# Once working, deploy to production
./install.sh --profile core,server
```

### 4. Document Machine Profiles

Keep a record of which profile each machine uses:

```
# My Machines
fedora-desktop:    --profile core,dev,desktop
rocky-server-01:   --profile core,server
raspberry-pi-4:    --profile core,dev --exclude gui
ubuntu-laptop:     --profile core,dev,desktop
```

### 5. Use Environment Detection

For SSH servers without display:

```bash
# Auto-exclude GUI if no display server
if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
    EXCLUDE_TAGS="${EXCLUDE_TAGS:+$EXCLUDE_TAGS,}gui"
fi
```

## Common Issues

### Packages Not Installing

**Problem:** Package has tags but doesn't install.

**Solution:** Check if tags match your profile:

```bash
# See package tags
yq eval '.packages.lazygit.tags' install/packages.yaml

# Make sure profile includes the tag
./install.sh --profile core,dev  # Now includes 'dev' tag
```

### Wrong Packages Installing

**Problem:** Desktop apps installing on server.

**Solution:** Use appropriate profile or exclusions:

```bash
# Use server profile
./install.sh --profile core,server

# Or exclude GUI
./install.sh --exclude gui
```

### Profile Not Taking Effect

**Problem:** Profile flag ignored.

**Solution:** Check environment variables:

```bash
# Unset conflicting variables
unset INSTALL_PROFILE
unset EXCLUDE_TAGS

# Then run with flags
./install.sh --profile core,dev
```

## Further Reading

- [Package Configuration](package-config.md) - YAML format reference
- [Custom Functions](custom-functions.md) - Complex installations
- [Installation Guide](../install/README.md) - Main installation docs
