#!/usr/bin/env bash
# Get the directory where the script is located
DIR="$(dirname "$0")"

# The path where AeroSpace looks for config
TARGET="./aerospace.toml"

# Start with main config
cat "$DIR/aerospace.main.toml" > "$TARGET"

# Append local rules if they exist
if [ -f "$DIR/aerospace.local.toml" ]; then
    echo -e "\n# --- Machine Specific Rules ---" >> "$TARGET"
    cat "$DIR/aerospace.local.toml" >> "$TARGET"
fi

# Reload AeroSpace
aerospace reload-config
