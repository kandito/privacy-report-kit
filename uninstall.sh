#!/usr/bin/env bash
set -euo pipefail
PACK_DIR="$HOME/.gemini/packs/privacy-report-kit"
CMD_LINK="$HOME/.gemini/commands/privacy-report.toml"
rm -f "$CMD_LINK"
rm -rf "$PACK_DIR"
echo "🧹 Uninstalled Privacy Report Kit."

