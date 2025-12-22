# Documentation

Complete documentation for the terminalConfig installation system.

## Documentation Structure

- **[custom-functions.md](custom-functions.md)** - Writing custom installation functions for complex packages
- **[package-config.md](package-config.md)** - YAML configuration format reference
- **[profiles.md](profiles.md)** - Profile system and tag-based filtering guide

## Quick Links

### Getting Started
- [Quick Start Guide](../QUICK_START.md) - One-page reference
- [Installation README](../install/README.md) - Main installation guide
- [Repository README](../README.md) - Project overview

### Advanced Topics
- [Custom Functions](custom-functions.md) - For packages requiring special handling
- [Package Configuration](package-config.md) - YAML format and options
- [Profile System](profiles.md) - Controlling what installs where

## Documentation Overview

### Custom Functions Guide

Learn how to write custom installation functions for:
- Architecture-specific binaries (ARM64 vs x86_64)
- Downloading from GitHub releases
- Building from source
- Platform-specific installation procedures

**Examples:**
- Neovim on Raspberry Pi (ARM64 binary)
- LazyGit from GitHub releases
- Building tools from source
- Conditional installations

**Read:** [custom-functions.md](custom-functions.md)

### Package Configuration Reference

Complete YAML configuration format reference:
- Basic package definitions
- Platform-specific configurations
- Installation methods (brew, COPR, PPA, AUR, function)
- Tag system for profiles
- Best practices and examples

**Examples:**
- Simple universal packages
- Platform-specific package names
- Using special repositories
- GUI and server-specific packages

**Read:** [package-config.md](package-config.md)

### Profile System Guide

Understand the tag-based profile system:
- Available profile tags (core, dev, desktop, server, optional)
- Common profiles (minimal, workstation, server, headless)
- Per-machine configuration
- Command line usage
- Debugging and troubleshooting

**Examples:**
- Desktop workstation setup
- Server installation
- Raspberry Pi headless setup
- Minimal installations

**Read:** [profiles.md](profiles.md)

## Common Questions

### How do I add a new package?

1. Add to `install/packages.yaml`:
   ```yaml
   my-package:
     default: my-package
     tags: [dev, optional]
   ```

2. If it needs special handling, add function to `install/install-functions.sh`:
   ```bash
   install_my_package() {
       local distro="$1"
       # Installation logic
   }
   ```

**More details:** [Package Configuration](package-config.md)

### How do I make a package install only on specific machines?

Use tags to control installation:

```yaml
ghostty:
  macos:
    method: brew
  tags: [desktop, gui]  # Only on desktop machines
```

Then install with appropriate profile:
```bash
# Desktop - includes ghostty
./install.sh --profile core,dev,desktop

# Server - excludes ghostty
./install.sh --profile core,server
```

**More details:** [Profile System](profiles.md)

### How do I handle architecture-specific binaries?

Use custom functions with architecture detection:

```bash
install_my_tool() {
    local distro="$1"
    local arch=$(get_arch)
    
    case "$arch" in
        x86_64) url="...x86_64.tar.gz" ;;
        arm64) url="...arm64.tar.gz" ;;
    esac
    
    curl -L "$url" | tar -xz ...
}
```

**More details:** [Custom Functions](custom-functions.md)

### How do I add support for a new platform?

1. Create `install/install-yourplatform.sh` (copy existing script as template)
2. Add platform detection to `install/install.sh`
3. Add platform-specific configs to `packages.yaml`
4. Test on the target platform

**More details:** [Installation README](../install/README.md)

## Best Practices

### Package Configuration

- ✅ Use `default` for packages with same name everywhere
- ✅ Only specify platform-specific differences
- ✅ Use appropriate tags (core, dev, desktop, server, optional)
- ✅ Group related packages with comments
- ✅ Document special cases

### Custom Functions

- ✅ Always handle all supported platforms
- ✅ Check architecture when downloading binaries
- ✅ Use `setup_user_bin()` for user-space tools
- ✅ Clean up temporary files
- ✅ Provide informative log messages
- ✅ Test on actual hardware (especially ARM64)

### Profile Usage

- ✅ Always include `core` in profiles
- ✅ Use exclusions for edge cases (`--exclude gui`)
- ✅ Test profiles before production deployment
- ✅ Document which profile each machine uses
- ✅ Consider per-machine configuration files

## Troubleshooting

### Package Not Installing

1. Check if package has correct tags
2. Verify profile includes those tags
3. Check YAML syntax is valid

**Solution:** [Profile System - Common Issues](profiles.md#common-issues)

### Custom Function Not Working

1. Verify function name matches package name (dash → underscore)
2. Check function handles your platform
3. Test function directly

**Solution:** [Custom Functions - Debugging](custom-functions.md#debugging-tips)

### YAML Syntax Error

1. Validate YAML: `yq eval install/packages.yaml`
2. Check indentation (use 2 spaces)
3. Ensure tags are arrays: `[core, dev]`

**Solution:** [Package Configuration - Validation](package-config.md#validation)

## Reference

### File Locations

```
terminalConfig/
├── install/
│   ├── packages.yaml           # Package definitions
│   ├── install-functions.sh    # Custom functions
│   ├── install-*.sh            # Platform installers
│   └── README.md               # Installation guide
├── docs/
│   ├── custom-functions.md     # This guide
│   ├── package-config.md       # YAML reference
│   └── profiles.md             # Profile guide
└── README.md                   # Main README
```

### Command Reference

```bash
# Installation
./install.sh                    # Full installation
./install.sh --profile core     # Minimal
./install.sh --profile core,dev # With dev tools
./install.sh --exclude gui      # No GUI apps
./install.sh --help             # Show help

# Validation
yq eval install/packages.yaml   # Check YAML syntax
yq eval '.packages.NAME'        # Check specific package

# Testing
source install-functions.sh     # Load functions
install_PACKAGE "fedora"        # Test function
```

### Tag Reference

| Tag | Purpose | Example Packages |
|-----|---------|------------------|
| `core` | Essential utilities | git, curl, tmux, neovim |
| `dev` | Development tools | lazygit, ripgrep, fd |
| `desktop` | Desktop apps | ghostty |
| `gui` | Requires display | Any GUI app |
| `server` | Server tools | docker, nginx |
| `optional` | Nice-to-have | btop, extras |

## Contributing

When contributing documentation:

1. **Keep examples practical** - Real-world use cases
2. **Test all code examples** - Ensure they work
3. **Update all affected docs** - Keep docs in sync
4. **Use clear headings** - Easy to scan
5. **Include troubleshooting** - Common issues

## Support

- **Issues:** [GitHub Issues](https://github.com/Aphadon/terminalConfig/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Aphadon/terminalConfig/discussions)
- **Installation Help:** [Installation README](../install/README.md)

## External Resources

- [YAML Specification](https://yaml.org/)
- [yq Documentation](https://mikefarah.gitbook.io/yq/)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [Oh My Bash](https://ohmybash.nntoan.com/)
- [Oh My Zsh](https://ohmyz.sh/)
