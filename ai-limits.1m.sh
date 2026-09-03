#!/bin/bash

# <xbar.title>Claude + Codex Usage</xbar.title>
# <xbar.version>1.2.0</xbar.version>
# <xbar.author>Roberto Pirozzi</xbar.author>
# <xbar.author.github>titopirozzi</xbar.author.github>
# <xbar.desc>Claude Code and Codex usage limits in the macOS menu bar.</xbar.desc>
# <xbar.dependencies>ai-usagebar</xbar.dependencies>
# <xbar.abouturl>https://github.com/titopirozzi/claude-codex-swiftbar</xbar.abouturl>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>

set -u

DATA_DIR="${SWIFTBAR_PLUGIN_DATA_PATH:-$HOME/Library/Application Support/ClaudeCodexSwiftBar}"
MODE_FILE="$DATA_DIR/display-mode"
ACTION_SCRIPT="${SWIFTBAR_PLUGIN_PATH:-$0}"

set_mode() {
  case "${1:-}" in
    full|compact|minimal|claude|codex)
      mkdir -p "$DATA_DIR"
      printf '%s\n' "$1" > "$MODE_FILE"
      ;;
  esac
}

if [[ "${1:-}" == "--set-mode" ]]; then
  set_mode "${2:-full}"
  exit 0
fi

MODE="full"
if [[ -r "$MODE_FILE" ]]; then
  read -r MODE < "$MODE_FILE" || MODE="full"
fi
case "$MODE" in
  full|compact|minimal|claude|codex) ;;
  *) MODE="full" ;;
esac

find_ai_usagebar() {
  if [[ -n "${AI_USAGEBAR:-}" && -x "${AI_USAGEBAR}" ]]; then
    printf '%s\n' "$AI_USAGEBAR"
    return 0
  fi

  local candidate
  for candidate in \
    "$HOME/.cargo/bin/ai-usagebar" \
    "/opt/homebrew/bin/ai-usagebar" \
    "/usr/local/bin/ai-usagebar"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  command -v ai-usagebar 2>/dev/null || return 1
}

AI="$(find_ai_usagebar || true)"

if [[ -z "$AI" ]]; then
  echo "⚠️ AI usage unavailable"
  echo "---"
  echo "ai-usagebar was not found."
  echo "Install it with: cargo install ai-usagebar"
  exit 0
fi

get_fields() {
  local vendor="$1"
  local format="$2"
  local raw

  if ! raw="$("$AI" --vendor "$vendor" --format "$format" --json 2>/dev/null)"; then
    return 1
  fi

  printf '%s' "$raw" | /usr/bin/python3 -c '
import sys, json, re
try:
    d = json.load(sys.stdin)
    t = re.sub(r"<[^>]+>", "", d.get("text", ""))
    print(t.replace(";;", chr(31)))
except Exception:
    sys.exit(1)
'
}

CLAUDE_FIELDS="$(get_fields anthropic '{session_pct};;{session_reset};;{weekly_pct};;{weekly_reset};;{scoped_model};;{scoped_pct};;{scoped_reset}' || true)"
CODEX_FIELDS="$(get_fields openai '{session_pct};;{session_reset};;{weekly_pct};;{weekly_reset}' || true)"

IFS=$'\x1f' read -r C5 C5R CW CWR CM CMP CMR <<< "$CLAUDE_FIELDS"
IFS=$'\x1f' read -r O5 O5R OW OWR <<< "$CODEX_FIELDS"

is_pct() {
  [[ "${1:-}" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

safe_pct() {
  local v="${1:-0}"
  v="${v%%.*}"
  [[ "$v" =~ ^[0-9]+$ ]] || v=0
  (( v < 0 )) && v=0
  (( v > 100 )) && v=100
  printf '%s\n' "$v"
}

bar() {
  local pct filled empty out i
  pct="$(safe_pct "${1:-0}")"
  filled=$((pct / 10))
  empty=$((10 - filled))
  out=""
  for ((i=0; i<filled; i++)); do out+="█"; done
  for ((i=0; i<empty; i++)); do out+="░"; done
  printf '%s\n' "$out"
}

status() {
  local pct
  pct="$(safe_pct "${1:-0}")"
  if (( pct >= 80 )); then
    echo "🔴"
  elif (( pct >= 60 )); then
    echo "🟠"
  else
    echo "🟢"
  fi
}

row() {
  local name="$1" pct="$2" reset="${3:-—}"
  [[ -n "$reset" ]] || reset="—"
  printf "%s %-8s %3s%%  %s   ↻ %s | font=Menlo size=12\n" \
    "$(status "$pct")" "$name" "$pct" "$(bar "$pct")" "$reset"
}

CLAUDE_AVAILABLE=false
CODEX_AVAILABLE=false
if is_pct "${C5:-}" || is_pct "${CW:-}" || is_pct "${CMP:-}"; then CLAUDE_AVAILABLE=true; fi
if is_pct "${O5:-}" || is_pct "${OW:-}"; then CODEX_AVAILABLE=true; fi

claude_full() {
  local title="⚡️ Claude"
  if is_pct "${C5:-}"; then title+=" 5h ${C5}%"; fi
  if is_pct "${CW:-}"; then title+=" · W ${CW}%"; fi
  if [[ -n "${CM:-}" ]] && is_pct "${CMP:-}"; then title+=" · ${CM} ${CMP}%"; fi
  printf '%s' "$title"
}

codex_full() {
  local title="🤖 Codex"
  if is_pct "${O5:-}"; then title+=" 5h ${O5}%"; fi
  if is_pct "${OW:-}"; then title+=" · W ${OW}%"; fi
  printf '%s' "$title"
}

claude_compact() {
  local values=""
  if is_pct "${C5:-}"; then values+="5h ${C5}"; fi
  if is_pct "${CW:-}"; then [[ -n "$values" ]] && values+="·"; values+="W${CW}"; fi
  if [[ -n "${CM:-}" ]] && is_pct "${CMP:-}"; then [[ -n "$values" ]] && values+="·"; values+="${CM:0:1}${CMP}"; fi
  printf '⚡️ Claude %s%%' "$values"
}

codex_compact() {
  local values=""
  if is_pct "${O5:-}"; then values+="5h ${O5}"; fi
  if is_pct "${OW:-}"; then [[ -n "$values" ]] && values+="·"; values+="W${OW}"; fi
  printf '🤖 Codex %s%%' "$values"
}

claude_minimal() {
  local values=""
  if is_pct "${C5:-}"; then values+="${C5}"; fi
  if is_pct "${CW:-}"; then [[ -n "$values" ]] && values+="·"; values+="${CW}"; fi
  if [[ -n "${CM:-}" ]] && is_pct "${CMP:-}"; then [[ -n "$values" ]] && values+="·"; values+="${CMP}"; fi
  printf '⚡️ %s' "$values"
}

codex_minimal() {
  local values=""
  if is_pct "${O5:-}"; then values+="${O5}"; fi
  if is_pct "${OW:-}"; then [[ -n "$values" ]] && values+="·"; values+="${OW}"; fi
  printf '🤖 %s' "$values"
}

join_available() {
  local c="$1" o="$2"
  if $CLAUDE_AVAILABLE && $CODEX_AVAILABLE; then
    echo "${c}  •  ${o}"
  elif $CLAUDE_AVAILABLE; then
    echo "$c"
  elif $CODEX_AVAILABLE; then
    echo "$o"
  else
    echo "⚠️ No Claude/Codex usage detected"
  fi
}

case "$MODE" in
  full)
    join_available "$( $CLAUDE_AVAILABLE && claude_full || true )" "$( $CODEX_AVAILABLE && codex_full || true )"
    ;;
  compact)
    join_available "$( $CLAUDE_AVAILABLE && claude_compact || true )" "$( $CODEX_AVAILABLE && codex_compact || true )"
    ;;
  minimal)
    join_available "$( $CLAUDE_AVAILABLE && claude_minimal || true )" "$( $CODEX_AVAILABLE && codex_minimal || true )"
    ;;
  claude)
    if $CLAUDE_AVAILABLE; then claude_full; echo; else echo "⚠️ Claude usage unavailable"; fi
    ;;
  codex)
    if $CODEX_AVAILABLE; then codex_full; echo; else echo "⚠️ Codex usage unavailable"; fi
    ;;
esac

echo "---"

SHOW_CLAUDE=false
SHOW_CODEX=false
case "$MODE" in
  claude) $CLAUDE_AVAILABLE && SHOW_CLAUDE=true ;;
  codex) $CODEX_AVAILABLE && SHOW_CODEX=true ;;
  *)
    $CLAUDE_AVAILABLE && SHOW_CLAUDE=true
    $CODEX_AVAILABLE && SHOW_CODEX=true
    ;;
esac

if $SHOW_CLAUDE; then
  echo "⚡️ CLAUDE CODE | font=Menlo-Bold size=13"
  if is_pct "${C5:-}"; then row "5-hour" "$C5" "${C5R:-—}"; fi
  if is_pct "${CW:-}"; then row "Weekly" "$CW" "${CWR:-—}"; fi
  if [[ -n "${CM:-}" ]] && is_pct "${CMP:-}"; then row "$CM" "$CMP" "${CMR:-—}"; fi
fi

if $SHOW_CLAUDE && $SHOW_CODEX; then echo "---"; fi

if $SHOW_CODEX; then
  echo "🤖 CODEX | font=Menlo-Bold size=13"
  if is_pct "${O5:-}"; then row "5-hour" "$O5" "${O5R:-—}"; fi
  if is_pct "${OW:-}"; then row "Weekly" "$OW" "${OWR:-—}"; fi
fi

if ! $SHOW_CLAUDE && ! $SHOW_CODEX; then
  case "$MODE" in
    claude) echo "Claude is selected, but no Claude usage was detected." ;;
    codex) echo "Codex is selected, but no Codex usage was detected." ;;
    *) echo "No authenticated Claude Code or Codex usage was returned." ;;
  esac
fi

echo "---"
echo "Display | font=Menlo-Bold size=12"

mode_item() {
  local id="$1" label="$2" checked="false"
  [[ "$MODE" == "$id" ]] && checked="true"
  echo "$label | bash='$ACTION_SCRIPT' param1='--set-mode' param2='$id' terminal=false refresh=true checked=$checked"
}

mode_item full    "Full — Claude + Codex"
mode_item compact "Compact — Claude + Codex"
mode_item minimal "Minimal — icons + numbers"
mode_item claude  "Claude only"
mode_item codex   "Codex only"

echo "---"
echo "↻ Refresh now | refresh=true font=Menlo size=12"
