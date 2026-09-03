#!/bin/bash

# <xbar.title>Claude + Codex Usage</xbar.title>
# <xbar.version>1.0.0</xbar.version>
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
  echo "⚠️ Claude/Codex usage unavailable"
  echo "---"
  echo "ai-usagebar was not found."
  echo "Install it with: cargo install ai-usagebar"
  exit 0
fi

get_fields() {
  "$AI" --vendor "$1" --format "$2" --json 2>/dev/null | /usr/bin/python3 -c '
import sys, json, re
try:
    d = json.load(sys.stdin)
    t = re.sub(r"<[^>]+>", "", d.get("text", ""))
    print(t.replace(";;", "\t"))
except Exception:
    print("")
'
}

IFS=$'\t' read -r C5 C5R CW CWR CM CMP CMR <<< "$(
  get_fields anthropic \
  '{session_pct};;{session_reset};;{weekly_pct};;{weekly_reset};;{scoped_model};;{scoped_pct};;{scoped_reset}'
)"

IFS=$'\t' read -r O5 O5R OW OWR <<< "$(
  get_fields openai \
  '{session_pct};;{session_reset};;{weekly_pct};;{weekly_reset}'
)"

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
  local name="$1" pct="${2:-0}" reset="${3:-—}"
  printf "%s %-8s %3s%%  %s   ↻ %s | font=Menlo size=12\n" \
    "$(status "$pct")" "$name" "$pct" "$(bar "$pct")" "$reset"
}

C5="${C5:-0}"
CW="${CW:-0}"
CMP="${CMP:-0}"
O5="${O5:-0}"
OW="${OW:-0}"
C5R="${C5R:-—}"
CWR="${CWR:-—}"
CMR="${CMR:-—}"
O5R="${O5R:-—}"
OWR="${OWR:-—}"
CM="${CM:-Fable}"

# Menu bar. Do not force a monospace font here; it can break emoji rendering.
echo "⚡️ Claude 5h ${C5}% · W ${CW}% · ${CM} ${CMP}%  •  🤖 Codex 5h ${O5}% · W ${OW}%"

echo "---"
echo "⚡️ CLAUDE CODE | font=Menlo-Bold size=13"
row "5-hour" "$C5" "$C5R"
row "Weekly" "$CW" "$CWR"
if [[ -n "$CM" && -n "$CMP" ]]; then
  row "$CM" "$CMP" "$CMR"
fi

echo "---"
echo "🤖 CODEX | font=Menlo-Bold size=13"
row "5-hour" "$O5" "$O5R"
row "Weekly" "$OW" "$OWR"

echo "---"
echo "↻ Actualizar ahora | refresh=true font=Menlo size=12"
