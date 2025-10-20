#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/kandito/privacy-report-kit.git}"
PACK_DIR="$HOME/.gemini/packs/privacy-report-kit"
CMD_DIR="$HOME/.gemini/commands"

echo "Installing Privacy Report Kit for Gemini CLI…"

# Ensure folders
mkdir -p "$HOME/.gemini/packs" "$CMD_DIR"

# Clone or update
if [ -d "$PACK_DIR/.git" ]; then
  git -C "$PACK_DIR" fetch --tags --quiet
  git -C "$PACK_DIR" checkout main --quiet
  git -C "$PACK_DIR" pull --quiet
else
  git clone --quiet "$REPO_URL" "$PACK_DIR"
fi

# Make helper executable
chmod +x "$PACK_DIR/tools/collect-privacy-context.sh"

# Symlink commands
ln -sf "$PACK_DIR/commands/privacy-report-json.toml" "$CMD_DIR/privacy-report-json.toml"
ln -sf "$PACK_DIR/commands/privacy-report.toml" "$CMD_DIR/privacy-report.toml"

echo "Checking dependencies…"
command -v rg >/dev/null || echo "Warning: ripgrep (rg) not found. Install via: brew install ripgrep | apt-get install ripgrep"
command -v jq >/dev/null || echo "Tip: jq optional but useful."

echo
echo "✅ Installed. Usage (in any repo with Gemini CLI): /privacy-report-json and /privacy-report"
