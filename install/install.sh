#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_logo() {
  print_color "$CYAN" "
    _    ____  _   _    _    ____   ___  _   _
   / \  |  _ \| | | |  / \  |  _ \ / _ \| \ | |
  / _ \ | |_) | |_| | / _ \ | | | | | | |  \| |
 / ___ \|  __/|  _  |/ ___ \| |_| | |_| | |\  |
/_/   \_\_|   |_| |_/_/   \_\____/ \___/|_| \_|
                  A  P  H  A  D  O  N
"
}

detect_package_manager() {
  if command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v brew >/dev/null 2>&1; then
    echo "brew"
  else
    echo "unknown"
  fi
}

is_installed() {
  local pkg="$1"
  case "$PKG_MANAGER" in
    apt)    dpkg -s "$pkg" &>/dev/null ;;
    dnf)    rpm -q "$pkg" &>/dev/null ;;
    yum)    rpm -q "$pkg" &>/dev/null ;;
    pacman) pacman -Qi "$pkg" &>/dev/null ;;
    brew)   brew list "$pkg" &>/dev/null ;;
    *)      return 1 ;;
  esac
}

install_package() {
  local pkg="$1"
  
  case "$PKG_MANAGER" in
    apt)    sudo apt install -y "$pkg" 2>/dev/null ;;
    dnf)    sudo dnf install -y "$pkg" 2>/dev/null ;;
    yum)    sudo yum install -y "$pkg" 2>/dev/null ;;
    pacman) sudo pacman -S --noconfirm "$pkg" 2>/dev/null ;;
    brew)   brew install "$pkg" 2>/dev/null ;;
    *)      return 1 ;;
  esac
}

update_package_manager() {
  print_info "Updating package manager..."
  case "$PKG_MANAGER" in
    apt)    sudo apt update ;;
    dnf)    sudo dnf check-update || true ;;
    yum)    sudo yum check-update || true ;;
    pacman) sudo pacman -Sy ;;
    brew)   brew update ;;
  esac
}

# Main script
clear
print_logo

# Detect package manager
PKG_MANAGER=$(detect_package_manager)
[ "$PKG_MANAGER" = "unknown" ] && die "No supported package manager found."
print_info "Using package manager: $PKG_MANAGER"
echo ""

# Find packages.conf
PACKAGES_FILE="$SCRIPT_DIR/packages.conf"
if [[ ! -f "$PACKAGES_FILE" ]]; then
  die "packages.conf not found at $PACKAGES_FILE"
fi

# Check if running with --all flag (skip selection menu)
if [[ "$1" == "--all" ]]; then
  SELECTED_SECTIONS=()
  while IFS= read -r section; do
    SELECTED_SECTIONS+=("$section")
  done < <(get_sections "$PACKAGES_FILE")
  print_info "Installing all sections: ${SELECTED_SECTIONS[*]}"
else
  # Interactive section selection
  select_sections "$PACKAGES_FILE"
  SELECTED_SECTIONS=("${SELECTED_SECTIONS_RESULT[@]}")
fi

if [[ ${#SELECTED_SECTIONS[@]} -eq 0 ]]; then
  print_warning "No sections selected. Exiting."
  exit 0
fi

# Gather packages from selected sections
ALL_PACKAGES=($(gather_packages_from_sections "$PACKAGES_FILE" "${SELECTED_SECTIONS[@]}"))

# Add macOS-specific packages
if [ "$PKG_MANAGER" = "brew" ]; then
  print_info "Detected macOS with Homebrew — adding 'aerospace'"
  ALL_PACKAGES+=("aerospace")
fi

if [[ ${#ALL_PACKAGES[@]} -eq 0 ]]; then
  print_warning "No packages to install. Exiting."
  exit 0
fi

# Check which packages need to be installed
clear
print_logo
print_color "$BLUE" "Checking package status..."
echo ""

TO_INSTALL=()
for pkg in "${ALL_PACKAGES[@]}"; do
  if is_installed "$pkg"; then
    print_success "$pkg is already installed"
  else
    print_info "$pkg will be installed"
    TO_INSTALL+=("$pkg")
  fi
done

echo ""

if [[ ${#TO_INSTALL[@]} -eq 0 ]]; then
  print_success "All packages already installed. Nothing to do."
  exit 0
fi

# Confirm installation
print_color "$YELLOW" "The following ${#TO_INSTALL[@]} package(s) will be installed:"
for pkg in "${TO_INSTALL[@]}"; do
  echo "  - $pkg"
done
echo ""

read -p "Proceed with installation? [Y/n] " confirm
case "$confirm" in
  [nN]*)
    print_warning "Installation cancelled."
    exit 0
    ;;
esac

# Update package manager first
update_package_manager
echo ""

# Install packages one by one, tracking failures
INSTALLED=()
FAILED=()

print_info "Installing packages..."
echo ""

for pkg in "${TO_INSTALL[@]}"; do
  printf "  Installing %-20s ... " "$pkg"
  if install_package "$pkg"; then
    print_success "done"
    INSTALLED+=("$pkg")
  else
    print_error "failed"
    FAILED+=("$pkg")
  fi
done

# Print summary
echo ""
print_color "$BLUE" "════════════════════════════════════════"
print_color "$BLUE" "           INSTALLATION SUMMARY         "
print_color "$BLUE" "════════════════════════════════════════"
echo ""

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
  print_success "Successfully installed (${#INSTALLED[@]}):"
  for pkg in "${INSTALLED[@]}"; do
    echo "    - $pkg"
  done
  echo ""
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
  print_error "Failed to install (${#FAILED[@]}):"
  for pkg in "${FAILED[@]}"; do
    echo "    - $pkg"
  done
  echo ""
  print_warning "Some packages may not be available for your system."
  print_info "You can try installing them manually or from alternative sources."
fi

echo ""
if [[ ${#FAILED[@]} -eq 0 ]]; then
  print_success "All packages installed successfully!"
else
  print_warning "Installation completed with ${#FAILED[@]} failure(s)."
fi
