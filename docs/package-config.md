# Package Configuration Reference

Complete YAML configuration format reference for `packages.yaml`.

## Table of Contents

- [Basic Format](#basic-format)
- [Configuration Options](#configuration-options)
- [Installation Methods](#installation-methods)
- [Tags System](#tags-system)
- [Examples](#examples)
- [Best Practices](#best-practices)

## Basic Format

```yaml
packages:
  package-name:
    # Configuration options here
```

## Configuration Options

### Simple Package (Same Everywhere)

```yaml
git:
  default: git
  tags: [core]
```

**Installs:** `git` package using standard package manager on all platforms.

### Platform-Specific Package Names

```yaml
fd:
  fedora: fd-find
  rocky: fd-find
  debian: fd-find
  ubuntu: fd-find
  arch: fd
  macos:
    package: fd
    method: brew
  tags: [dev]
```

**Installs:** Different package name per platform (fd-find vs fd).

### Platform-Specific Methods

```yaml
lazygit:
  fedora:
    package: lazygit
    method: copr:jesseduffield/lazygit
  rocky:
    method: function
  debian:
    method: function
  ubuntu:
    method: function
  arch:
    package: lazygit
  macos:
    method: brew
  tags: [dev]
```

## Installation Methods

### Standard Package Manager (default)

```yaml
curl:
  default: curl
  tags: [core]
```

No method specified = use standard package manager (`dnf`, `apt`, `pacman`, `brew`).

### Homebrew (macOS)

```yaml
package:
  macos:
    method: brew
```

Uses `brew install package`.

### COPR Repository (Fedora/Rocky)

```yaml
package:
  fedora:
    package: package-name
    method: copr:user/repository
```

Enables COPR repository, then installs package:
```bash
sudo dnf copr enable user/repository
sudo dnf install package-name
```

### PPA Repository (Ubuntu/Debian)

```yaml
package:
  ubuntu:
    package: package-name
    method: ppa:user/repository
```

Adds PPA, then installs package:
```bash
sudo add-apt-repository ppa:user/repository
sudo apt-get install package-name
```

### AUR (Arch User Repository)

```yaml
package:
  arch:
    method: aur
```

Installs using AUR helper (`yay`):
```bash
yay -S package-name
```

### Custom Function

```yaml
package:
  debian:
    method: function
```

Calls `install_package()` function from `install-functions.sh`.

### Skip Package

```yaml
package:
  macos:
    skip: true
```

Package will not be installed on this platform.

## Tags System

Tags control which packages install with different profiles.

### Available Tags

| Tag | Purpose | Example Packages |
|-----|---------|------------------|
| `core` | Essential utilities | git, curl, tmux, neovim |
| `dev` | Development tools | lazygit, ripgrep, fd, bat |
| `desktop` | Desktop applications | ghostty |
| `gui` | GUI applications | Any app requiring display server |
| `server` | Server-specific tools | docker, nginx |
| `optional` | Nice-to-have packages | btop, ffmpegthumbnailer |

### Tag Syntax

```yaml
package:
  default: package
  tags: [core, dev]  # Array of tags
```

### How Tags Work

```bash
# Install only core packages
./install.sh --profile core

# Install core + dev packages
./install.sh --profile core,dev

# Install everything except GUI
./install.sh --exclude gui
```

**Matching Logic:**
- Package installs if ANY of its tags match the profile
- Package is excluded if ANY of its tags match --exclude
- If profile is "full", all non-excluded packages install

## Examples

### Example 1: Universal Package

```yaml
git:
  default: git
  tags: [core]
```

- Same name on all platforms
- Standard package manager
- Tagged as core (always installs)

### Example 2: Different Names

```yaml
delta:
  fedora: git-delta
  rocky: git-delta
  debian: git-delta
  ubuntu: git-delta
  arch: git-delta
  macos:
    package: git-delta
    method: brew
  tags: [dev]
```

- Package name is `git-delta` on most platforms
- Tagged as dev (only with `--profile dev`)

### Example 3: Special Repository

```yaml
yazi:
  fedora:
    package: yazi
    method: copr:atim/yazi
  rocky:
    method: function
  debian:
    method: function
  ubuntu:
    method: function
  arch:
    package: yazi
  macos:
    method: brew
  tags: [core]
```

- Fedora: COPR repository
- Rocky/Debian/Ubuntu: Custom function (GitHub binary)
- Arch: Standard repo
- macOS: Homebrew

### Example 4: GUI Application

```yaml
ghostty:
  fedora:
    method: function
  ubuntu:
    method: function
  macos:
    method: brew
  tags: [desktop, gui]
```

- Only installs on desktop machines
- Excluded automatically on servers (no desktop/gui tags)
- Can be explicitly excluded: `--exclude gui`

### Example 5: Platform-Specific Package

```yaml
aerospace:
  macos:
    method: brew
  tags: [desktop, gui, macos-only]
```

- Only defined for macOS
- Tagged for desktop + GUI + macOS-only
- Other platforms skip automatically (no config)

### Example 6: Optional Package

```yaml
btop:
  default: btop
  macos:
    method: brew
  tags: [optional]
```

- Available on all platforms
- Tagged as optional
- Installs with `--profile full` or `--profile optional`
- Can exclude: `--profile core,dev --exclude optional`

### Example 7: Server-Only Tool

```yaml
docker:
  fedora: docker
  rocky: docker
  debian: docker.io
  ubuntu: docker.io
  arch: docker
  tags: [server]
```

- Different package name on Debian/Ubuntu
- Only installs with `--profile server`
- Excluded from desktop installations

## Field Reference

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `default` | string | No | Package name for all platforms |
| `tags` | array | Yes | Profile tags for filtering |
| `fedora` | string/object | No | Fedora-specific config |
| `rocky` | string/object | No | Rocky Linux config |
| `debian` | string/object | No | Debian config |
| `ubuntu` | string/object | No | Ubuntu config |
| `arch` | string/object | No | Arch Linux config |
| `macos` | string/object | No | macOS config |

### Platform-Specific Object Fields

| Field | Type | Description |
|-------|------|-------------|
| `package` | string | Package name for this platform |
| `method` | string | Installation method |
| `skip` | boolean | Skip on this platform |

## Best Practices

### 1. Use `default` for Common Packages

```yaml
# GOOD: Simple and clean
curl:
  default: curl
  tags: [core]

# BAD: Repetitive
curl:
  fedora: curl
  rocky: curl
  debian: curl
  ubuntu: curl
  arch: curl
  macos:
    method: brew
  tags: [core]
```

### 2. Only Specify Differences

```yaml
# GOOD: Only specify what's different
fd:
  fedora: fd-find
  debian: fd-find
  ubuntu: fd-find
  arch: fd  # Only Arch is different
  macos:
    package: fd
    method: brew
  tags: [dev]
```

### 3. Use Appropriate Tags

```yaml
# GOOD: Multiple relevant tags
neovim:
  tags: [core]  # Essential tool

lazygit:
  tags: [dev]  # Development tool

ghostty:
  tags: [desktop, gui]  # Desktop GUI app

btop:
  tags: [optional]  # Nice-to-have
```

### 4. Group Related Packages

```yaml
# Use comments to organize
# ============================================================================
# Core Utilities
# ============================================================================

git:
  default: git
  tags: [core]

curl:
  default: curl
  tags: [core]

# ============================================================================
# Development Tools
# ============================================================================

lazygit:
  # ...
```

### 5. Document Special Cases

```yaml
# Neovim: Uses function for ARM64 Raspberry Pi support
neovim:
  fedora:
    package: neovim
  rocky:
    method: function  # Old version in repos
  debian:
    method: function  # ARM64 binary for Raspberry Pi
  ubuntu:
    method: function  # PPA for latest version
  arch:
    package: neovim
  macos:
    method: brew
  tags: [core]
```

## Validation

### Check YAML Syntax

```bash
# Validate YAML format
yq eval install/packages.yaml

# Pretty print
yq eval install/packages.yaml -P

# Check specific package
yq eval '.packages.neovim' install/packages.yaml
```

### Common Errors

**Invalid YAML:**
```yaml
# WRONG: Missing colon
git
  default: git

# CORRECT
git:
  default: git
```

**Invalid Tag Format:**
```yaml
# WRONG: Not an array
tags: core, dev

# CORRECT
tags: [core, dev]
```

**Inconsistent Indentation:**
```yaml
# WRONG: Mixed spaces/tabs
git:
  default: git
    tags: [core]

# CORRECT: Consistent 2-space indent
git:
  default: git
  tags: [core]
```

## Testing Configurations

### Test Specific Package

```bash
# Query package configuration
yq eval '.packages.neovim' install/packages.yaml

# Check tags
yq eval '.packages.neovim.tags[]' install/packages.yaml

# Check Fedora config
yq eval '.packages.neovim.fedora' install/packages.yaml
```

### Test Profile Filtering

```bash
# See what would install
./install.sh --profile core 2>&1 | grep "Installing:"

# Check exclusions
./install.sh --exclude gui 2>&1 | grep "Excluding:"
```

## Further Reading

- [YAML Syntax](https://yaml.org/spec/1.2/spec.html)
- [yq Documentation](https://mikefarah.gitbook.io/yq/)
- [Custom Functions Guide](custom-functions.md)
- [Profile System](profiles.md)
