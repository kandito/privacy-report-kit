#!/usr/bin/env bash
set -euo pipefail

# This script is designed to be called by collect-privacy-context.sh
# It takes a single Prisma schema file as input and extracts model and field information.

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <schema_file>"
  exit 1
fi

schema_file="$1"

awk '
  /model/ {
    model_name = $2
  }
  /\w+\s+\w+/ {
    if (model_name) {
      field_name = $1
      print field_name " -> " model_name "." field_name
    }
  }
' "$schema_file"
