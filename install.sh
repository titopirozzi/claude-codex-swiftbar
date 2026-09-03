#!/bin/bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/ai-limits.1m.sh"
PLUGIN_DIR="${1:-${SWIFTBAR_PLUGIN_DIR:-$HOME/Documents/SwiftBar}}"
PLUGIN_PATH="$PLUGIN_DIR/ai-limits.1m.sh"

echo "Installing Claude + Codex SwiftBar plugin..."

if ! command -v swiftbar >/dev/null 2>&1 && [[ ! -d "/Applications/SwiftBar.app" ]]; then
  echo "SwiftBar is not installed."
  echo "Install it with: brew install swiftbar"
  exit 1
fi

if ! command -v ai-usagebar >/dev/null 2>&1 && [[ ! -x "$HOME/.cargo/bin/ai-usagebar" ]]; then
  echo "ai-usagebar is not installed."
  echo "Install Rust first if needed, then run: cargo install ai-usagebar"
  exit 1
fi

mkdir -p "$PLUGIN_DIR"
curl -fsSL "$REPO_RAW" -o "$PLUGIN_PATH"
chmod +x "$PLUGIN_PATH"

echo "Installed to: $PLUGIN_PATH"
echo
if [[ "$PLUGIN_DIR" == "$HOME/Documents/SwiftBar" ]]; then
  echo "Open SwiftBar and select this folder as the Plugin Folder if you have not already:"
  echo "  $PLUGIN_DIR"
else
  echo "Make sure SwiftBar's Plugin Folder points to:"
  echo "  $PLUGIN_DIR"
fi

echo
open -a SwiftBar >/dev/null 2>&1 || true
echo "Done. The menu bar item should appear shortly."
