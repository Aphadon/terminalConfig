#!/bin/bash

print_logo() {
    cat << "EOF"
    _    ____  _   _    _    ____   ___  _   _
   / \  |  _ \| | | |  / \  |  _ \ / _ \| \ | |
  / _ \ | |_) | |_| | / _ \ | | | | | | |  \| |
 / ___ \|  __/|  _  |/ ___ \| |_| | |_| | |\  |
/_/   \_\_|   |_| |_/_/   \_\____/ \___/|_| \_|
                  A  P  H  A  D  O  N
EOF
}

die() {
  echo "Error: $1" >&2
  exit 1
}

DEFAULT_PACKAGES=("curl" "git")

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

read_packages_from_files() {
  local files=("$@")
  local pkgs=()

  for file in "${files[@]}"; do
    if [ -f "$file" ]; then
      while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        pkgs+=("$line")
      done < "$file"
    else
      die "Package list file not found: $file"
    fi
  done

  echo "${pkgs[@]}"
}

gather_packages() {
  local args=()
  local files=()
  local result=()

  for arg in "$@"; do
    if [[ -f "$arg" ]]; then
      files+=("$arg")
    else
      args+=("$arg")
    fi
  done

  if [ ${#args[@]} -eq 0 ] && [ ${#files[@]} -eq 0 ]; then
    result=("${DEFAULT_PACKAGES[@]}")
  else
    result+=("${args[@]}")
    result+=($(read_packages_from_files "${files[@]}"))
  fi

  echo "${result[@]}"
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

clear
print_logo

PKG_MANAGER=$(detect_package_manager)
[ "$PKG_MANAGER" = "unknown" ] && die "No supported package manager found."
echo "Using package manager: $PKG_MANAGER"

ALL_PACKAGES=($(gather_packages "$@"))
[ ${#ALL_PACKAGES[@]} -eq 0 ] && die "No packages specified."
 # Append macOS-specific package

if [ "$PKG_MANAGER" = "brew" ]; then
  echo "Detected macOS with Homebrew — adding 'aerospace'"
  ALL_PACKAGES+=("aerospace")
fi

TO_INSTALL=()
for pkg in "${ALL_PACKAGES[@]}"; do
  if is_installed "$pkg"; then
    echo "✓ $pkg is already installed"
  else
    echo "➕ $pkg will be installed"
    TO_INSTALL+=("$pkg")
  fi
done

if [ ${#TO_INSTALL[@]} -eq 0 ]; then
  echo "All packages already installed. Nothing to do."
  exit 0
fi

case "$PKG_MANAGER" in
  apt)    sudo apt update && sudo apt install -y "${TO_INSTALL[@]}" ;;
  dnf)    sudo dnf install -y "${TO_INSTALL[@]}" ;;
  yum)    sudo yum install -y "${TO_INSTALL[@]}" ;;
  pacman) sudo pacman -Sy --noconfirm "${TO_INSTALL[@]}" ;;
  brew)   brew install "${TO_INSTALL[@]}" ;;
  *)      die "Installer for $PKG_MANAGER not implemented." ;;
esac

