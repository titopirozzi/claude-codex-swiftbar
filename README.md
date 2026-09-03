# Claude + Codex SwiftBar

A small macOS menu bar plugin that shows **Claude Code** and **OpenAI Codex** usage limits in one place.

It works with **Claude only**, **Codex only**, or **both at the same time**, and includes five selectable display modes so it can fit anything from a large desktop monitor to a crowded MacBook menu bar.

## What it shows

Default **Full** mode:

```text
⚡️ Claude 5h 64% · W 60% · Fable 48%  •  🤖 Codex 5h 13% · W 73%
```

Click the item to see the detailed usage windows, visual bars, reset countdowns, and display controls.

The plugin can show:

- Claude Code 5-hour usage
- Claude Code weekly usage
- Claude model-specific weekly limit, such as **Fable**, when provided
- Codex 5-hour usage
- Codex weekly usage
- reset countdown for every available limit
- visual 10-step usage bars
- status indicators

Status colors:

- 🟢 below 60%
- 🟠 60%–79%
- 🔴 80% and above

The plugin refreshes every minute and also refreshes when you open the menu.

## Five display modes

Open the SwiftBar item and choose a mode under **Display**. The selected mode is saved and remains active after refreshes and restarts.

| Mode | Example | Best for |
|---|---|---|
| **Full — Claude + Codex** | `⚡️ Claude 5h 64% · W 60% · Fable 48% • 🤖 Codex 5h 13% · W 73%` | Large monitors |
| **Compact — Claude + Codex** | `⚡️ Claude 5h 64·W60·F48% • 🤖 Codex 5h 13·W73%` | MacBooks / smaller menu bars |
| **Minimal — icons + numbers** | `⚡️ 64·60·48 • 🤖 13·73` | Very limited menu-bar space |
| **Claude only** | `⚡️ Claude 5h 64% · W 60% · Fable 48%` | People who want Claude visible only |
| **Codex only** | `🤖 Codex 5h 13% · W 73%` | People who want Codex visible only |

The selected option is marked with a checkmark in the dropdown.

If you select **Claude only** or **Codex only**, the other provider is hidden from both the top menu bar and the detailed dropdown. If the selected provider is not authenticated or does not return usage data, the plugin shows a clear unavailable message instead of a fake `0%`.

## Provider detection

The plugin detects a provider only when `ai-usagebar` returns at least one real numeric usage metric for it.

| Setup | Behavior in Full / Compact / Minimal modes |
|---|---|
| Claude + Codex | Shows both providers separated by `•` |
| Claude only | Shows only Claude |
| Codex only | Shows only Codex |
| Neither available | Shows `⚠️ No Claude/Codex usage detected` |

Missing windows are hidden individually. For example, if Codex returns weekly usage but no 5-hour window, only the weekly metric is shown.

The plugin never substitutes an unavailable provider or unavailable window with a fake `0%`.

## Why this exists

`ai-usagebar` exposes the individual usage windows for Claude and Codex, but this plugin is focused on keeping the most useful limits visible **simultaneously** in the macOS menu bar.

It adds a SwiftBar-friendly presentation layer, selectable layouts, provider filtering, detailed reset information, and visual usage bars.

## Requirements

- macOS
- [SwiftBar](https://github.com/swiftbar/SwiftBar)
- [ai-usagebar](https://github.com/akitaonrails/ai-usagebar)
- Claude Code and/or Codex CLI authenticated, depending on what you use

You do **not** need both Claude Code and Codex installed.

## Do I need to use Claude or Codex in Terminal?

**No.** You do not need to keep Terminal open, and you do not need to do your day-to-day AI work from Terminal.

The plugin only needs the provider's official CLI to be **installed and authenticated at least once**, because `ai-usagebar` reuses the local credentials created by those CLIs.

For Claude Code, run this once and complete sign-in if prompted:

```bash
claude
```

For Codex, run this once and complete sign-in if prompted:

```bash
codex
```

After that, you can close Terminal. The SwiftBar plugin keeps reading the usage limits when it refreshes.

| What you use | What you need to authenticate |
|---|---|
| Claude only | `claude` once |
| Codex only | `codex` once |
| Claude + Codex | both once |

If another app already uses the same local Claude Code or Codex CLI credentials, the plugin may work immediately.

## Quick install

### 1. Install SwiftBar

With Homebrew:

```bash
brew install swiftbar
```

Open SwiftBar once and select a Plugin Folder. The examples below use:

```text
~/Documents/SwiftBar
```

### 2. Install ai-usagebar

If you do not already have Rust/Cargo:

```bash
curl https://sh.rustup.rs -sSf | sh
source "$HOME/.cargo/env"
```

Then install `ai-usagebar`:

```bash
cargo install ai-usagebar
```

### 3. Authenticate the provider(s) you use

Claude Code:

```bash
claude
```

Codex:

```bash
codex
```

Run only the CLI(s) you actually use and sign in if needed.

### 4. Install this plugin

```bash
curl -fsSL https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/install.sh | bash
```

The installer places the plugin at:

```text
~/Documents/SwiftBar/ai-limits.1m.sh
```

## Manual install

```bash
mkdir -p ~/Documents/SwiftBar
curl -fsSL \
  https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/ai-limits.1m.sh \
  -o ~/Documents/SwiftBar/ai-limits.1m.sh
chmod +x ~/Documents/SwiftBar/ai-limits.1m.sh
open -a SwiftBar
```

Then make sure SwiftBar's Plugin Folder is set to `~/Documents/SwiftBar`.

## Dropdown view

In Full mode with both providers available, clicking the menu bar item shows something like:

```text
⚡️ CLAUDE CODE
🟠 5-hour    64%  ██████░░░░   ↻ 3h 05m
🟠 Weekly    60%  ██████░░░░   ↻ 4d 17h
🟢 Fable     48%  ████░░░░░░   ↻ 4d 17h

🤖 CODEX
🟢 5-hour    13%  █░░░░░░░░░   ↻ 2h 36m
🟠 Weekly    73%  ███████░░░   ↻ 3d 17h

Display
✓ Full — Claude + Codex
  Compact — Claude + Codex
  Minimal — icons + numbers
  Claude only
  Codex only

↻ Refresh now
```

Changing the display option immediately refreshes the SwiftBar item and stores the preference locally.

## Understanding the labels

| Label | Meaning |
|---|---|
| `Claude 5h` | Claude Code rolling 5-hour window |
| `W` after Claude | Claude weekly usage |
| `Fable` | Claude model-specific weekly window, when exposed by the account |
| `Codex 5h` | Codex rolling 5-hour window |
| `W` after Codex | Codex weekly usage |

Percentages are **used**, not remaining.

So `Codex W 73%` means 73% has been consumed and about 27% remains until reset.

## Refresh interval

SwiftBar reads the refresh interval from the filename.

The included plugin is named:

```text
ai-limits.1m.sh
```

That means **refresh every 1 minute**.

Examples:

```text
ai-limits.30s.sh   # every 30 seconds
ai-limits.5m.sh    # every 5 minutes
```

After renaming, SwiftBar may treat it as a new plugin item and you may need to reposition it in the menu bar.

## Moving the item in the menu bar

Hold **Command (⌘)** and drag the item left or right in the macOS menu bar.

## Custom ai-usagebar location

The plugin automatically checks:

```text
~/.cargo/bin/ai-usagebar
/opt/homebrew/bin/ai-usagebar
/usr/local/bin/ai-usagebar
PATH
```

You can also explicitly set:

```bash
export AI_USAGEBAR="/custom/path/to/ai-usagebar"
```

## Troubleshooting

### `ai-usagebar was not found`

Check:

```bash
~/.cargo/bin/ai-usagebar --version
```

or:

```bash
which ai-usagebar
```

If missing:

```bash
cargo install ai-usagebar
```

### `No Claude/Codex usage detected`

Authenticate at least one provider and refresh SwiftBar:

```bash
claude
```

and/or:

```bash
codex
```

### Claude values are missing

Run Claude Code once and make sure you are logged in:

```bash
claude
```

Then test directly:

```bash
~/.cargo/bin/ai-usagebar --vendor anthropic --format '{session_pct} {weekly_pct} {scoped_model} {scoped_pct}' --json
```

### Codex values are missing

Make sure the Codex CLI is installed and authenticated:

```bash
codex --version
codex
```

Then test:

```bash
~/.cargo/bin/ai-usagebar --vendor openai --format '{session_pct} {weekly_pct}' --json
```

### Fable is missing

The model-specific line is driven by `ai-usagebar`'s scoped-model fields. If Claude does not currently expose a model-specific weekly window for the account, those values may be empty.

The plugin does not invent a Fable value; it displays what `ai-usagebar` reports.

### Emojis look wrong in the menu bar

The top menu bar line intentionally does **not** force the Menlo font. Forcing a monospace font there can cause macOS emoji such as ⚡️ to render as small monochrome symbols.

The dropdown uses Menlo because fixed-width text makes the usage bars easier to scan.

## How it works

This project is only a display layer.

It calls `ai-usagebar` separately for Anthropic and OpenAI and reads these documented placeholders:

Claude:

```text
{session_pct}
{session_reset}
{weekly_pct}
{weekly_reset}
{scoped_model}
{scoped_pct}
{scoped_reset}
```

Codex:

```text
{session_pct}
{session_reset}
{weekly_pct}
{weekly_reset}
```

The script detects which providers and windows contain numeric usage data, builds the selected menu-bar layout, and renders the detailed SwiftBar dropdown locally.

The chosen display mode is stored locally in SwiftBar's plugin data directory (with a user Library fallback outside SwiftBar).

No Claude or Codex credentials are stored by this plugin.

## Credits

This project depends on and is made possible by:

- [ai-usagebar](https://github.com/akitaonrails/ai-usagebar) by AkitaOnRails — provides the Claude/Codex usage data and reset windows.
- [SwiftBar](https://github.com/swiftbar/SwiftBar) — renders the script as a native macOS menu bar item.

Both upstream projects are MIT licensed.

## Privacy

This plugin does not transmit credentials itself and does not maintain its own usage database.

It invokes your locally installed `ai-usagebar` binary and displays the returned usage values through SwiftBar.

Review the upstream projects for the exact authentication and network behavior involved in retrieving usage data.

## Contributing

Issues and pull requests are welcome.

Useful ideas for future versions:

- configurable warning thresholds
- optional remaining-percent mode
- optional code-review or credit metrics from Codex
- configurable labels and icons
- support for more `ai-usagebar` providers

## License

MIT © 2026 Roberto Pirozzi
