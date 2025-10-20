#!/usr/bin/env bash
set -euo pipefail
PACK_DIR="$HOME/.gemini/packs/privacy-report-kit"
rm -f "$HOME/.gemini/commands/privacy-report-json.toml"
rm -f "$HOME/.gemini/commands/privacy-report.toml"
rm -rf "$PACK_DIR"
echo "🧹 Uninstalled Privacy Report Kit."

