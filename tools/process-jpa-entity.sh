#!/usr/bin/env bash
set -euo pipefail

# This script is designed to be called by collect-privacy-context.sh
# It takes a single Java file as input and extracts JPA table and column information.

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <java_file>"
  exit 1
fi

java_file="$1"

# Extract table name
table_name=$(grep -oP '(?<=@Table(name = "))[^"]+' "$java_file" || true)
if [ -z "$table_name" ]; then
  table_name=$(grep -oP '(?<=@Entity\s*\npublic class )\w+' "$java_file" | sed 's/\([a-z0-9]\)\([A-Z]\)/\1_\2/g' | tr '[:upper:]' '[:lower:]')
fi

# Find all fields and their column names
grep -E "(@Column|private)" "$java_file" | while read -r line; do
  if [[ "$line" == *"@Column"* ]]; then
    column_name=$(echo "$line" | grep -oP '(?<=name = ")[^"]+')
    field_name=$(echo "$line" | grep -oP '(?<=private \w+ )\w+')
    echo "$field_name -> $table_name.$column_name"
  elif [[ "$line" == *"private"* ]]; then
    field_name=$(echo "$line" | grep -oP '(?<=private \w+ )\w+')
    column_name=$(echo "$field_name" | sed 's/\([a-z0-9]\)\([A-Z]\)/\1_\2/g' | tr '[:upper:]' '[:lower:]')
    echo "$field_name -> $table_name.$column_name"
  fi
done
