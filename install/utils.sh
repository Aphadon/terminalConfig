#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_color() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${NC}"
}

print_success() { print_color "$GREEN" "✓ $1"; }
print_error() { print_color "$RED" "✗ $1"; }
print_info() { print_color "$CYAN" "➜ $1"; }
print_warning() { print_color "$YELLOW" "⚠ $1"; }

die() {
  print_error "$1" >&2
  exit 1
}

# Parse packages.conf and extract section names
get_sections() {
  local file="$1"
  grep -E '^\[.+\]$' "$file" | sed 's/\[\(.*\)\]/\1/'
}

# Get packages for a specific section
get_packages_for_section() {
  local file="$1"
  local section="$2"
  local in_section=false
  local packages=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Check if we hit a section header
    if [[ "$line" =~ ^\[(.+)\]$ ]]; then
      if [[ "${BASH_REMATCH[1]}" == "$section" ]]; then
        in_section=true
      else
        in_section=false
      fi
      continue
    fi

    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

    # Add package if we're in the right section
    if $in_section; then
      packages+=("$line")
    fi
  done < "$file"

  echo "${packages[@]}"
}

# Global variable to store selected sections (avoids nameref issues)
SELECTED_SECTIONS_RESULT=()

# Display section selection menu
select_sections() {
  local file="$1"
  local sections=()
  local choices=()
  
  # Read sections into array properly
  while IFS= read -r section; do
    sections+=("$section")
  done < <(get_sections "$file")

  # Initialize all sections as selected (1)
  for i in "${!sections[@]}"; do
    choices[$i]=1
  done

  while true; do
    clear
    print_color "$BLUE" "╔════════════════════════════════════════╗"
    print_color "$BLUE" "║       SELECT PACKAGE CATEGORIES        ║"
    print_color "$BLUE" "╚════════════════════════════════════════╝"
    echo ""

    for i in "${!sections[@]}"; do
      local section="${sections[$i]}"
      local pkg_count=0
      while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && ((pkg_count++))
      done < <(get_packages_for_section "$file" "$section" | tr ' ' '\n')
      
      if [[ ${choices[$i]} -eq 1 ]]; then
        print_color "$GREEN" "  [$((i+1))] [✓] $section ($pkg_count packages)"
      else
        print_color "$RED" "  [$((i+1))] [ ] $section ($pkg_count packages)"
      fi
    done

    echo ""
    print_color "$YELLOW" "  [a] Select all"
    print_color "$YELLOW" "  [n] Select none"
    print_color "$YELLOW" "  [v] View packages in sections"
    print_color "$GREEN" "  [c] Continue with installation"
    print_color "$RED" "  [q] Quit"
    echo ""
    read -p "Enter choice: " choice

    case "$choice" in
      [1-9]|[1-9][0-9])
        local idx=$((choice - 1))
        if [[ $idx -ge 0 && $idx -lt ${#sections[@]} ]]; then
          if [[ ${choices[$idx]} -eq 1 ]]; then
            choices[$idx]=0
          else
            choices[$idx]=1
          fi
        fi
        ;;
      a|A)
        for i in "${!sections[@]}"; do
          choices[$i]=1
        done
        ;;
      n|N)
        for i in "${!sections[@]}"; do
          choices[$i]=0
        done
        ;;
      v|V)
        clear
        print_color "$BLUE" "Package Details:"
        echo ""
        for i in "${!sections[@]}"; do
          local section="${sections[$i]}"
          print_color "$CYAN" "[$section]"
          for pkg in $(get_packages_for_section "$file" "$section"); do
            echo "  - $pkg"
          done
          echo ""
        done
        read -p "Press Enter to continue..."
        ;;
      c|C)
        break
        ;;
      q|Q)
        exit 0
        ;;
    esac
  done

  # Build list of selected sections into global variable
  SELECTED_SECTIONS_RESULT=()
  for i in "${!sections[@]}"; do
    if [[ ${choices[$i]} -eq 1 ]]; then
      SELECTED_SECTIONS_RESULT+=("${sections[$i]}")
    fi
  done
}

# Gather all packages from selected sections
gather_packages_from_sections() {
  local file="$1"
  shift
  local sections=("$@")
  local all_packages=()

  for section in "${sections[@]}"; do
    local packages=($(get_packages_for_section "$file" "$section"))
    all_packages+=("${packages[@]}")
  done

  echo "${all_packages[@]}"
}
