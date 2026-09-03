#!/bin/bash

# <xbar.title>Claude + Codex Usage</xbar.title>
# <xbar.version>1.1.0</xbar.version>
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
    print(t.replace(";;", "\t"))
except Exception:
    sys.exit(1)
'
}

CLAUDE_FIELDS="$(get_fields anthropic '{session_pct};;{session_reset};;{weekly_pct};;{weekly_reset};;{scoped_model};;{scoped_pct};;{scoped_reset}' || true)"
CODEX_FIELDS="$(get_fields openai '{session_pct};;{session_reset};;{weekly_pct};;{weekly_reset}' || true)"

IFS=$'\t' read -r C5 C5R CW CWR CM CMP CMR <<< "$CLAUDE_FIELDS"
IFS=$'\t' read -r O5 O5R OW OWR <<< "$CODEX_FIELDS"

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

if is_pct "${C5:-}" || is_pct "${CW:-}" || is_pct "${CMP:-}"; then
  CLAUDE_AVAILABLE=true
fi

if is_pct "${O5:-}" || is_pct "${OW:-}"; then
  CODEX_AVAILABLE=true
fi

# Build only the provider sections that actually exist.
CLAUDE_TITLE=""
if $CLAUDE_AVAILABLE; then
  CLAUDE_TITLE="⚡️ Claude"
  if is_pct "${C5:-}"; then CLAUDE_TITLE+=" 5h ${C5}%"; fi
  if is_pct "${CW:-}"; then CLAUDE_TITLE+=" · W ${CW}%"; fi
  if [[ -n "${CM:-}" ]] && is_pct "${CMP:-}"; then CLAUDE_TITLE+=" · ${CM} ${CMP}%"; fi
fi

CODEX_TITLE=""
if $CODEX_AVAILABLE; then
  CODEX_TITLE="🤖 Codex"
  if is_pct "${O5:-}"; then CODEX_TITLE+=" 5h ${O5}%"; fi
  if is_pct "${OW:-}"; then CODEX_TITLE+=" · W ${OW}%"; fi
fi

if $CLAUDE_AVAILABLE && $CODEX_AVAILABLE; then
  echo "${CLAUDE_TITLE}  •  ${CODEX_TITLE}"
elif $CLAUDE_AVAILABLE; then
  echo "$CLAUDE_TITLE"
elif $CODEX_AVAILABLE; then
  echo "$CODEX_TITLE"
else
  echo "⚠️ No Claude/Codex usage detected"
fi

echo "---"

if $CLAUDE_AVAILABLE; then
  echo "⚡️ CLAUDE CODE | font=Menlo-Bold size=13"
  if is_pct "${C5:-}"; then row "5-hour" "$C5" "${C5R:-—}"; fi
  if is_pct "${CW:-}"; then row "Weekly" "$CW" "${CWR:-—}"; fi
  if [[ -n "${CM:-}" ]] && is_pct "${CMP:-}"; then
    row "$CM" "$CMP" "${CMR:-—}"
  fi
fi

if $CLAUDE_AVAILABLE && $CODEX_AVAILABLE; then
  echo "---"
fi

if $CODEX_AVAILABLE; then
  echo "🤖 CODEX | font=Menlo-Bold size=13"
  if is_pct "${O5:-}"; then row "5-hour" "$O5" "${O5R:-—}"; fi
  if is_pct "${OW:-}"; then row "Weekly" "$OW" "${OWR:-—}"; fi
fi

if ! $CLAUDE_AVAILABLE && ! $CODEX_AVAILABLE; then
  echo "No authenticated Claude Code or Codex usage was returned."
  echo "Run the CLI you use and sign in, then refresh:"
  echo "claude"
  echo "codex"
fi

echo "---"
echo "↻ Actualizar ahora | refresh=true font=Menlo size=12"
