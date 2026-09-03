#!/bin/bash

# <xbar.title>Claude + Codex Usage</xbar.title>
# <xbar.version>1.3.0</xbar.version>
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

CURRENT_VERSION="1.3.0"
REMOTE_SCRIPT_URL="https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/ai-limits.1m.sh"
UPDATE_CHECK_INTERVAL=21600

DATA_DIR="${SWIFTBAR_PLUGIN_DATA_PATH:-$HOME/Library/Application Support/ClaudeCodexSwiftBar}"
MODE_FILE="$DATA_DIR/display-mode"
METRICS_FILE="$DATA_DIR/metrics-enabled"
RESET_STYLE_FILE="$DATA_DIR/reset-style"
AUTO_UPDATE_FILE="$DATA_DIR/auto-update"
UPDATE_LAST_CHECK_FILE="$DATA_DIR/update-last-check"
UPDATE_REMOTE_VERSION_FILE="$DATA_DIR/update-remote-version"
ACTION_SCRIPT="${SWIFTBAR_PLUGIN_PATH:-$0}"

mkdir -p "$DATA_DIR" 2>/dev/null || true

set_mode() {
  case "${1:-}" in
    full|compact|minimal|claude|codex)
      printf '%s\n' "$1" > "$MODE_FILE"
      ;;
  esac
}

ensure_metrics_file() {
  if [[ ! -f "$METRICS_FILE" ]]; then
    printf '%s\n' \
      claude_5h \
      claude_weekly \
      claude_scoped \
      codex_5h \
      codex_weekly > "$METRICS_FILE"
  fi
}

metric_enabled() {
  ensure_metrics_file
  /usr/bin/grep -qx "$1" "$METRICS_FILE" 2>/dev/null
}

toggle_metric() {
  local key="$1"
  case "$key" in
    claude_5h|claude_weekly|claude_scoped|codex_5h|codex_weekly) ;;
    *) return 0 ;;
  esac
  ensure_metrics_file
  local tmp="$DATA_DIR/metrics.tmp.$$"
  if metric_enabled "$key"; then
    /usr/bin/grep -vx "$key" "$METRICS_FILE" > "$tmp" || true
  else
    /bin/cat "$METRICS_FILE" > "$tmp" 2>/dev/null || true
    printf '%s\n' "$key" >> "$tmp"
  fi
  /bin/mv "$tmp" "$METRICS_FILE"
}

set_reset_style() {
  case "${1:-}" in
    relative|absolute) printf '%s\n' "$1" > "$RESET_STYLE_FILE" ;;
  esac
}

set_auto_update() {
  case "${1:-}" in
    on|off) printf '%s\n' "$1" > "$AUTO_UPDATE_FILE" ;;
  esac
}

version_gt() {
  /usr/bin/python3 - "$1" "$2" <<'PY'
import sys

def parts(v):
    out=[]
    for p in v.strip().lstrip('v').split('.'):
        n=''.join(ch for ch in p if ch.isdigit())
        out.append(int(n or 0))
    return (out+[0,0,0])[:3]

sys.exit(0 if parts(sys.argv[1]) > parts(sys.argv[2]) else 1)
PY
}

extract_version() {
  /usr/bin/sed -n 's/.*<xbar.version>\([^<]*\)<\/xbar.version>.*/\1/p' "$1" | /usr/bin/head -n 1
}

check_for_update() {
  local force="${1:-false}"
  local now last=0 tmp remote=""
  now="$(/bin/date +%s)"
  [[ -r "$UPDATE_LAST_CHECK_FILE" ]] && read -r last < "$UPDATE_LAST_CHECK_FILE" || last=0

  if [[ "$force" != "true" ]] && [[ "$last" =~ ^[0-9]+$ ]] && (( now - last < UPDATE_CHECK_INTERVAL )); then
    [[ -r "$UPDATE_REMOTE_VERSION_FILE" ]] && read -r remote < "$UPDATE_REMOTE_VERSION_FILE" || true
    printf '%s' "$remote"
    return 0
  fi

  tmp="$DATA_DIR/update-check.$$"
  if /usr/bin/curl -fsSL --max-time 5 "$REMOTE_SCRIPT_URL" -o "$tmp" 2>/dev/null; then
    remote="$(extract_version "$tmp")"
    if [[ -n "$remote" ]]; then
      printf '%s\n' "$remote" > "$UPDATE_REMOTE_VERSION_FILE"
      printf '%s\n' "$now" > "$UPDATE_LAST_CHECK_FILE"
    fi
  fi
  /bin/rm -f "$tmp"

  if [[ -z "$remote" && -r "$UPDATE_REMOTE_VERSION_FILE" ]]; then
    read -r remote < "$UPDATE_REMOTE_VERSION_FILE" || true
  fi
  printf '%s' "$remote"
}

perform_update() {
  local tmp="$DATA_DIR/plugin-update.$$"
  local remote=""

  if ! /usr/bin/curl -fsSL --max-time 15 "$REMOTE_SCRIPT_URL" -o "$tmp" 2>/dev/null; then
    /bin/rm -f "$tmp"
    return 1
  fi

  remote="$(extract_version "$tmp")"
  if [[ -z "$remote" ]] || ! /usr/bin/head -n 1 "$tmp" | /usr/bin/grep -q '^#!/bin/bash'; then
    /bin/rm -f "$tmp"
    return 1
  fi

  if [[ "$remote" == "$CURRENT_VERSION" ]] || ! version_gt "$remote" "$CURRENT_VERSION"; then
    printf '%s\n' "$remote" > "$UPDATE_REMOTE_VERSION_FILE"
    printf '%s\n' "$(/bin/date +%s)" > "$UPDATE_LAST_CHECK_FILE"
    /bin/rm -f "$tmp"
    return 0
  fi

  if ! /bin/cat "$tmp" > "$ACTION_SCRIPT"; then
    /bin/rm -f "$tmp"
    return 1
  fi
  /bin/chmod +x "$ACTION_SCRIPT" 2>/dev/null || true
  printf '%s\n' "$remote" > "$UPDATE_REMOTE_VERSION_FILE"
  printf '%s\n' "$(/bin/date +%s)" > "$UPDATE_LAST_CHECK_FILE"
  /bin/rm -f "$tmp"
  return 0
}

case "${1:-}" in
  --set-mode)
    set_mode "${2:-full}"
    exit 0
    ;;
  --toggle-metric)
    toggle_metric "${2:-}"
    exit 0
    ;;
  --set-reset-style)
    set_reset_style "${2:-relative}"
    exit 0
    ;;
  --set-auto-update)
    set_auto_update "${2:-off}"
    exit 0
    ;;
  --update-now)
    perform_update
    exit $?
    ;;
  --check-update)
    check_for_update true >/dev/null
    exit 0
    ;;
esac

MODE="full"
if [[ -r "$MODE_FILE" ]]; then read -r MODE < "$MODE_FILE" || MODE="full"; fi
case "$MODE" in full|compact|minimal|claude|codex) ;; *) MODE="full" ;; esac

RESET_STYLE="relative"
if [[ -r "$RESET_STYLE_FILE" ]]; then read -r RESET_STYLE < "$RESET_STYLE_FILE" || RESET_STYLE="relative"; fi
case "$RESET_STYLE" in relative|absolute) ;; *) RESET_STYLE="relative" ;; esac

AUTO_UPDATE="off"
if [[ -r "$AUTO_UPDATE_FILE" ]]; then read -r AUTO_UPDATE < "$AUTO_UPDATE_FILE" || AUTO_UPDATE="off"; fi
case "$AUTO_UPDATE" in on|off) ;; *) AUTO_UPDATE="off" ;; esac

REMOTE_VERSION="$(check_for_update false)"
if [[ "$AUTO_UPDATE" == "on" && -n "$REMOTE_VERSION" ]] && version_gt "$REMOTE_VERSION" "$CURRENT_VERSION"; then
  if perform_update; then
    exec "$ACTION_SCRIPT"
  fi
fi

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

get_fields() {
  local vendor="$1" format="$2" raw
  if ! raw="$("$AI" --vendor "$vendor" --format "$format" --json 2>/dev/null)"; then return 1; fi
  printf '%s' "$raw" | /usr/bin/python3 -c '
import sys, json, re
try:
    d=json.load(sys.stdin)
    t=re.sub(r"<[^>]+>", "", d.get("text", ""))
    print(t.replace(";;", chr(31)))
except Exception:
    sys.exit(1)
'
}

is_pct() { [[ "${1:-}" =~ ^[0-9]+([.][0-9]+)?$ ]]; }

safe_pct() {
  local v="${1:-0}"
  v="${v%%.*}"
  [[ "$v" =~ ^[0-9]+$ ]] || v=0
  (( v < 0 )) && v=0
  (( v > 100 )) && v=100
  printf '%s\n' "$v"
}

bar() {
  local pct filled empty out="" i
  pct="$(safe_pct "${1:-0}")"
  filled=$((pct / 10)); empty=$((10 - filled))
  for ((i=0; i<filled; i++)); do out+="█"; done
  for ((i=0; i<empty; i++)); do out+="░"; done
  printf '%s\n' "$out"
}

status() {
  local pct
  pct="$(safe_pct "${1:-0}")"
  if (( pct >= 80 )); then echo "🔴"; elif (( pct >= 60 )); then echo "🟠"; else echo "🟢"; fi
}

format_reset() {
  local reset="${1:-—}"
  [[ -n "$reset" ]] || reset="—"
  if [[ "$RESET_STYLE" == "relative" || "$reset" == "—" ]]; then
    printf '%s' "$reset"
    return
  fi

  /usr/bin/python3 - "$reset" <<'PY'
import re, sys
from datetime import datetime, timedelta

s=sys.argv[1]
parts=re.findall(r'(\d+)\s*([dhm])', s.lower())
if not parts:
    print(s, end='')
    raise SystemExit
seconds=0
for n,u in parts:
    seconds += int(n) * {'d':86400,'h':3600,'m':60}[u]
now=datetime.now()
target=now+timedelta(seconds=seconds)
time=target.strftime('%I:%M %p').lstrip('0')
if target.date()==now.date():
    out=f'Today {time}'
elif target.date()==(now+timedelta(days=1)).date():
    out=f'Tomorrow {time}'
else:
    date=target.strftime('%b %d').replace(' 0',' ')
    out=f'{date}, {time}'
print(out, end='')
PY
}

row() {
  local name="$1" pct="$2" reset="${3:-—}" shown_reset
  shown_reset="$(format_reset "$reset")"
  printf "%s %-8s %3s%%  %s   ↻ %s | font=Menlo size=12\n" \
    "$(status "$pct")" "$name" "$pct" "$(bar "$pct")" "$shown_reset"
}

CLAUDE_AVAILABLE=false
CODEX_AVAILABLE=false
C5=""; C5R=""; CW=""; CWR=""; CM=""; CMP=""; CMR=""
O5=""; O5R=""; OW=""; OWR=""

if [[ -n "$AI" ]]; then
  CLAUDE_FIELDS="$(get_fields anthropic '{session_pct};;{session_reset};;{weekly_pct};;{weekly_reset};;{scoped_model};;{scoped_pct};;{scoped_reset}' || true)"
  CODEX_FIELDS="$(get_fields openai '{session_pct};;{session_reset};;{weekly_pct};;{weekly_reset}' || true)"
  IFS=$'\x1f' read -r C5 C5R CW CWR CM CMP CMR <<< "$CLAUDE_FIELDS"
  IFS=$'\x1f' read -r O5 O5R OW OWR <<< "$CODEX_FIELDS"
  if is_pct "${C5:-}" || is_pct "${CW:-}" || is_pct "${CMP:-}"; then CLAUDE_AVAILABLE=true; fi
  if is_pct "${O5:-}" || is_pct "${OW:-}"; then CODEX_AVAILABLE=true; fi
fi

claude_has_visible_metric() {
  (metric_enabled claude_5h && is_pct "${C5:-}") || \
  (metric_enabled claude_weekly && is_pct "${CW:-}") || \
  (metric_enabled claude_scoped && [[ -n "${CM:-}" ]] && is_pct "${CMP:-}")
}

codex_has_visible_metric() {
  (metric_enabled codex_5h && is_pct "${O5:-}") || \
  (metric_enabled codex_weekly && is_pct "${OW:-}")
}

CLAUDE_VISIBLE=false
CODEX_VISIBLE=false
$CLAUDE_AVAILABLE && claude_has_visible_metric && CLAUDE_VISIBLE=true
$CODEX_AVAILABLE && codex_has_visible_metric && CODEX_VISIBLE=true

claude_full() {
  local title="⚡️ Claude"
  if metric_enabled claude_5h && is_pct "${C5:-}"; then title+=" 5h ${C5}%"; fi
  if metric_enabled claude_weekly && is_pct "${CW:-}"; then title+=" · W ${CW}%"; fi
  if metric_enabled claude_scoped && [[ -n "${CM:-}" ]] && is_pct "${CMP:-}"; then title+=" · ${CM} ${CMP}%"; fi
  printf '%s' "$title"
}

codex_full() {
  local title="🤖 Codex"
  if metric_enabled codex_5h && is_pct "${O5:-}"; then title+=" 5h ${O5}%"; fi
  if metric_enabled codex_weekly && is_pct "${OW:-}"; then title+=" · W ${OW}%"; fi
  printf '%s' "$title"
}

claude_compact() {
  local values=""
  if metric_enabled claude_5h && is_pct "${C5:-}"; then values+="5h ${C5}"; fi
  if metric_enabled claude_weekly && is_pct "${CW:-}"; then [[ -n "$values" ]] && values+="·"; values+="W${CW}"; fi
  if metric_enabled claude_scoped && [[ -n "${CM:-}" ]] && is_pct "${CMP:-}"; then [[ -n "$values" ]] && values+="·"; values+="${CM:0:1}${CMP}"; fi
  printf '⚡️ Claude %s%%' "$values"
}

codex_compact() {
  local values=""
  if metric_enabled codex_5h && is_pct "${O5:-}"; then values+="5h ${O5}"; fi
  if metric_enabled codex_weekly && is_pct "${OW:-}"; then [[ -n "$values" ]] && values+="·"; values+="W${OW}"; fi
  printf '🤖 Codex %s%%' "$values"
}

claude_minimal() {
  local values=""
  if metric_enabled claude_5h && is_pct "${C5:-}"; then values+="${C5}"; fi
  if metric_enabled claude_weekly && is_pct "${CW:-}"; then [[ -n "$values" ]] && values+="·"; values+="${CW}"; fi
  if metric_enabled claude_scoped && [[ -n "${CM:-}" ]] && is_pct "${CMP:-}"; then [[ -n "$values" ]] && values+="·"; values+="${CMP}"; fi
  printf '⚡️ %s' "$values"
}

codex_minimal() {
  local values=""
  if metric_enabled codex_5h && is_pct "${O5:-}"; then values+="${O5}"; fi
  if metric_enabled codex_weekly && is_pct "${OW:-}"; then [[ -n "$values" ]] && values+="·"; values+="${OW}"; fi
  printf '🤖 %s' "$values"
}

join_visible() {
  local c="$1" o="$2"
  if $CLAUDE_VISIBLE && $CODEX_VISIBLE; then echo "${c}  •  ${o}"
  elif $CLAUDE_VISIBLE; then echo "$c"
  elif $CODEX_VISIBLE; then echo "$o"
  elif [[ -z "$AI" ]]; then echo "⚠️ AI usage unavailable"
  elif $CLAUDE_AVAILABLE || $CODEX_AVAILABLE; then echo "⚙️ No metrics selected"
  else echo "⚠️ No Claude/Codex usage detected"
  fi
}

case "$MODE" in
  full) join_visible "$( $CLAUDE_VISIBLE && claude_full || true )" "$( $CODEX_VISIBLE && codex_full || true )" ;;
  compact) join_visible "$( $CLAUDE_VISIBLE && claude_compact || true )" "$( $CODEX_VISIBLE && codex_compact || true )" ;;
  minimal) join_visible "$( $CLAUDE_VISIBLE && claude_minimal || true )" "$( $CODEX_VISIBLE && codex_minimal || true )" ;;
  claude)
    if $CLAUDE_VISIBLE; then claude_full; echo
    elif $CLAUDE_AVAILABLE; then echo "⚙️ No Claude metrics selected"
    else echo "⚠️ Claude usage unavailable"; fi
    ;;
  codex)
    if $CODEX_VISIBLE; then codex_full; echo
    elif $CODEX_AVAILABLE; then echo "⚙️ No Codex metrics selected"
    else echo "⚠️ Codex usage unavailable"; fi
    ;;
esac

echo "---"

SHOW_CLAUDE=false
SHOW_CODEX=false
case "$MODE" in
  claude) $CLAUDE_VISIBLE && SHOW_CLAUDE=true ;;
  codex) $CODEX_VISIBLE && SHOW_CODEX=true ;;
  *) $CLAUDE_VISIBLE && SHOW_CLAUDE=true; $CODEX_VISIBLE && SHOW_CODEX=true ;;
esac

if $SHOW_CLAUDE; then
  echo "⚡️ CLAUDE CODE | font=Menlo-Bold size=13"
  if metric_enabled claude_5h && is_pct "${C5:-}"; then row "5-hour" "$C5" "${C5R:-—}"; fi
  if metric_enabled claude_weekly && is_pct "${CW:-}"; then row "Weekly" "$CW" "${CWR:-—}"; fi
  if metric_enabled claude_scoped && [[ -n "${CM:-}" ]] && is_pct "${CMP:-}"; then row "$CM" "$CMP" "${CMR:-—}"; fi
fi

if $SHOW_CLAUDE && $SHOW_CODEX; then echo "---"; fi

if $SHOW_CODEX; then
  echo "🤖 CODEX | font=Menlo-Bold size=13"
  if metric_enabled codex_5h && is_pct "${O5:-}"; then row "5-hour" "$O5" "${O5R:-—}"; fi
  if metric_enabled codex_weekly && is_pct "${OW:-}"; then row "Weekly" "$OW" "${OWR:-—}"; fi
fi

if ! $SHOW_CLAUDE && ! $SHOW_CODEX; then
  if [[ -z "$AI" ]]; then
    echo "ai-usagebar was not found."
    echo "Install it with: cargo install ai-usagebar"
  elif $CLAUDE_AVAILABLE || $CODEX_AVAILABLE; then
    echo "No enabled metrics are currently visible in this display mode."
  else
    echo "No authenticated Claude Code or Codex usage was returned."
  fi
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
echo "Metrics | font=Menlo-Bold size=12"
metric_item() {
  local key="$1" label="$2" checked="false"
  metric_enabled "$key" && checked="true"
  echo "$label | bash='$ACTION_SCRIPT' param1='--toggle-metric' param2='$key' terminal=false refresh=true checked=$checked"
}
echo "Claude"
metric_item claude_5h "--5-hour"
metric_item claude_weekly "--Weekly"
metric_item claude_scoped "--${CM:-Model-specific}"
echo "Codex"
metric_item codex_5h "--5-hour"
metric_item codex_weekly "--Weekly"

echo "---"
echo "Reset display | font=Menlo-Bold size=12"
reset_item() {
  local id="$1" label="$2" checked="false"
  [[ "$RESET_STYLE" == "$id" ]] && checked="true"
  echo "$label | bash='$ACTION_SCRIPT' param1='--set-reset-style' param2='$id' terminal=false refresh=true checked=$checked"
}
reset_item relative "Relative — 3h 18m"
reset_item absolute "Absolute — Today 8:40 PM"

echo "---"
echo "Updates | font=Menlo-Bold size=12"
echo "Version $CURRENT_VERSION"
if [[ -n "$REMOTE_VERSION" ]] && version_gt "$REMOTE_VERSION" "$CURRENT_VERSION"; then
  echo "⬆️ Update available: $REMOTE_VERSION | bash='$ACTION_SCRIPT' param1='--update-now' terminal=false refresh=true"
elif [[ -n "$REMOTE_VERSION" ]]; then
  echo "✓ Up to date"
else
  echo "Update status unavailable"
fi
AUTO_CHECKED="false"
[[ "$AUTO_UPDATE" == "on" ]] && AUTO_CHECKED="true"
NEXT_AUTO="on"; [[ "$AUTO_UPDATE" == "on" ]] && NEXT_AUTO="off"
echo "Automatic updates | bash='$ACTION_SCRIPT' param1='--set-auto-update' param2='$NEXT_AUTO' terminal=false refresh=true checked=$AUTO_CHECKED"
echo "Check for updates now | bash='$ACTION_SCRIPT' param1='--check-update' terminal=false refresh=true"

echo "---"
echo "↻ Refresh now | refresh=true font=Menlo size=12"
