# Claude + Codex SwiftBar

A small macOS menu bar plugin that shows **Claude Code** and **OpenAI Codex** usage limits **at the same time**.

It is designed for people who actively use both tools and want the important limits visible without opening separate apps or switching providers.

## What it shows

In the macOS menu bar:

```text
⚡️ Claude 5h 64% · W 60% · Fable 48%  •  🤖 Codex 5h 13% · W 73%
```

Click the item to open a more detailed view with:

- Claude Code 5-hour usage
- Claude Code weekly usage
- Claude model-specific weekly limit (for example **Fable**, when provided)
- Codex 5-hour usage
- Codex weekly usage
- reset countdown for every limit
- visual 10-step usage bars
- status indicators

Status colors:

- 🟢 below 60%
- 🟠 60%–79%
- 🔴 80% and above

The plugin refreshes every minute and also refreshes when you open the menu.

## Why this exists

`ai-usagebar` already exposes the individual usage windows for Claude and Codex, but its standard macOS overview focuses on one primary metric per provider.

This SwiftBar plugin combines the values into one persistent menu bar item so you can watch **Claude 5h + Weekly + model limit + Codex 5h + Weekly simultaneously**.

## Requirements

- macOS
- [SwiftBar](https://github.com/swiftbar/SwiftBar)
- [ai-usagebar](https://github.com/akitaonrails/ai-usagebar)
- Claude Code logged in at least once
- Codex CLI logged in at least once

SwiftBar supports executable scripts in a Plugin Folder and uses the filename refresh interval, so `ai-limits.1m.sh` refreshes every minute.

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

### 3. Make sure Claude Code and Codex are authenticated

Run each CLI once and sign in if needed:

```bash
claude
codex
```

`ai-usagebar` reuses the official CLI credentials for Claude and Codex.

### 4. Install this plugin

```bash
curl -fsSL https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/install.sh | bash
```

The installer places the plugin at:

```text
~/Documents/SwiftBar/ai-limits.1m.sh
```

If your SwiftBar Plugin Folder is somewhere else, run:

```bash
SWIFTBAR_PLUGIN_DIR="/your/plugin/folder" \
  curl -fsSL https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/install.sh | bash
```

If your shell does not preserve that variable across a piped command, use the manual install below instead.

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

## Understanding the menu bar

Example:

```text
⚡️ Claude 5h 64% · W 60% · Fable 48%  •  🤖 Codex 5h 13% · W 73%
```

Meaning:

| Label | Meaning |
|---|---|
| `Claude 5h` | Claude Code rolling 5-hour window |
| `W` after Claude | Claude weekly usage |
| `Fable` | Claude's model-specific weekly window, when exposed by the account |
| `Codex 5h` | Codex rolling 5-hour window |
| `W` after Codex | Codex weekly usage |

Percentages are **used**, not remaining.

So `Codex W 73%` means 73% has been consumed and about 27% remains until reset.

## Dropdown view

Clicking the menu bar item shows something like:

```text
⚡️ CLAUDE CODE
🟠 5-hour    64%  ██████░░░░   ↻ 3h 05m
🟠 Weekly    60%  ██████░░░░   ↻ 4d 17h
🟢 Fable     48%  ████░░░░░░   ↻ 4d 17h

🤖 CODEX
🟢 5-hour    13%  █░░░░░░░░░   ↻ 2h 36m
🟠 Weekly    73%  ███████░░░   ↻ 3d 17h
```

There is also a manual **Actualizar ahora** action at the bottom.

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

The script strips the formatting markup returned in the JSON `text` field, builds the compact menu bar title, and renders the detailed SwiftBar dropdown locally.

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
- compact/verbose display modes
- optional remaining-percent mode
- optional code-review or credit metrics from Codex
- configurable labels and icons
- support for more `ai-usagebar` providers

## License

MIT © 2026 Roberto Pirozzi
