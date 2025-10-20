#!/usr/bin/env bash
set -euo pipefail

# This script is designed to be called by collect-privacy-context.sh
# It takes a single JavaScript/TypeScript file as input and extracts Mongoose collection and field information.

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <model_file>"
  exit 1
fi

model_file="$1"

# Extract collection name
collection_name=$(grep -oP '(?<=mongoose.model(")")[^"]+' "$model_file" || true)
if [ -z "$collection_name" ]; then
  collection_name=$(basename "$model_file" .js | sed 's/\( [a-z0-9]\)\( [A-Z]\)/\1_\2/g' | tr '[:upper:]' '[:lower:]')
fi

# Find all fields
grep -oP '(?<=const \w+ = new Schema())\{[^}]+\}' "$model_file" | grep -oP '\w+:' | tr -d ':' | while read -r field_name; do
  echo "$field_name -> $collection_name.$field_name"
done
