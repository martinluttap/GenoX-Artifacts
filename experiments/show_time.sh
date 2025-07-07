#!/bin/bash

# Usage: ./script.sh <substring1> [substring2] [substring3] [substring4] [substring5]
# Substrings may contain dash (-) characters.

if [ "$#" -lt 1 ] || [ "$#" -gt 5 ]; then
    echo "Usage: $0 <substring1> [substring2] [substring3] [substring4] [substring5]"
    exit 1
fi

substr1="$1"
substr2="${2:-}"
substr3="${3:-}"
substr4="${4:-}"
substr5="${5:-}"

# Find folders containing all provided substrings (including dashes)
folders=$(find . -type d -name "*$substr1*")
for substr in "$substr2" "$substr3" "$substr4" "$substr5"; do
    if [ -n "$substr" ]; then
        # Use grep -F for fixed string matching (handles dashes safely)
        folders=$(echo "$folders" | grep -F "$substr")
    fi
done

folder=$(echo "$folders" | head -n 1)

if [ -z "$folder" ]; then
    echo "No folder found containing the provided substrings."
    exit 1
fi

echo "Found folder: $folder"

# Show last 2 lines of each .csv file in the folder
for csvfile in "$folder"/*cpu*.csv; do
    if [ -f "$csvfile" ]; then
        echo "==> $csvfile <=="
        tail -n 1 "$csvfile"
    fi
done