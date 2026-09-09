#!/bin/bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/ai-limits.1m.sh"
PLUGIN_DIR="${1:-${SWIFTBAR_PLUGIN_DIR:-$HOME/Documents/SwiftBar}}"
PLUGIN_PATH="$PLUGIN_DIR/ai-limits.1m.sh"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_LABEL="com.titopirozzi.claude-codex-swiftbar"
LAUNCH_AGENT_PATH="$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_LABEL.plist"

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
curl -fsSL \
  -H 'Cache-Control: no-cache' \
  -H 'Pragma: no-cache' \
  "${REPO_RAW}?ts=$(date +%s)" \
  -o "$PLUGIN_PATH"
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
mkdir -p "$LAUNCH_AGENT_DIR"
cat > "$LAUNCH_AGENT_PATH" <<EOF_PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LAUNCH_AGENT_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/open</string>
    <string>-a</string>
    <string>SwiftBar</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>LimitLoadToSessionType</key>
  <string>Aqua</string>
</dict>
</plist>
EOF_PLIST

plutil -lint "$LAUNCH_AGENT_PATH" >/dev/null
launchctl bootout "gui/$UID" "$LAUNCH_AGENT_PATH" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$UID" "$LAUNCH_AGENT_PATH"

echo "SwiftBar will now launch automatically when you log in."
echo
open -a SwiftBar >/dev/null 2>&1 || true
echo "Done. The menu bar item should appear shortly."
