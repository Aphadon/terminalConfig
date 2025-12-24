#!/usr/bin/env bash

# Get the directory where the script is located
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MAIN_SRC="$DIR/aerospace.main.toml"
LOCAL_SRC="$DIR/aerospace.local.toml"
OUTPUT="$DIR/aerospace.toml"

# 1. Start with the tracked main config
cat "$MAIN_SRC" > "$OUTPUT"

# 2. Append local rules if they exist
if [ -f "$LOCAL_SRC" ]; then
    echo -e "\n# --- Local Machine Rules ---" >> "$OUTPUT"
    cat "$LOCAL_SRC" >> "$OUTPUT"
    echo "Successfully merged local rules."
else
    echo "No local rules found, using main config only."
fi

# 3. Reload AeroSpace to pick up changes
aerospace reload-config
