# Claude + Codex SwiftBar

A small macOS menu bar plugin that shows **Claude Code** and **OpenAI Codex** usage limits in one place.

It works with **Claude only**, **Codex only**, or **both at the same time**, and lets you control exactly what appears in the menu bar.

## What it shows

Default **Full** mode:

```text
⚡️ Claude 5h 64% · W 60% · Fable 48%  •  🤖 Codex 5h 13% · W 73%
```

Click the item to see detailed usage windows, bars, reset information, display controls, metric toggles, and update controls.

The plugin can show:

- Claude Code 5-hour usage
- Claude Code weekly usage
- Claude model-specific weekly usage, such as **Fable**, when provided
- Codex 5-hour usage
- Codex weekly usage
- reset time for every visible limit
- 10-step usage bars
- status indicators

Status colors:

- 🟢 below 60%
- 🟠 60%–79%
- 🔴 80% and above

The plugin refreshes every minute and also refreshes when you open the menu.

## Display modes

Open the SwiftBar item and choose a mode under **Display**. The selected mode is saved locally.

| Mode | Example | Best for |
|---|---|---|
| **Full — Claude + Codex** | `⚡️ Claude 5h 64% · W 60% · Fable 48% • 🤖 Codex 5h 13% · W 73%` | Large monitors |
| **Compact — Claude + Codex** | `⚡️ Claude 5h 64·W60·F48% • 🤖 Codex 5h 13·W73%` | MacBooks |
| **Minimal — icons + numbers** | `⚡️ 64·60·48 • 🤖 13·73` | Very limited menu-bar space |
| **Claude only** | `⚡️ Claude 5h 64% · W 60% · Fable 48%` | Show Claude only |
| **Codex only** | `🤖 Codex 5h 13% · W 73%` | Show Codex only |

If a provider is not authenticated or does not return usage data, it is hidden automatically instead of showing a fake `0%`.

## Choose exactly which metrics appear

Starting in **v1.3.0**, each usage window can be enabled or disabled independently from the dropdown.

Claude:

- 5-hour
- Weekly
- model-specific window such as Fable

Codex:

- 5-hour
- Weekly

For example, you can disable every metric except the two weekly windows and get:

```text
⚡️ Claude · W 60%  •  🤖 Codex · W 73%
```

The same selection also controls which rows appear in the detailed dropdown.

Your metric choices are saved locally and remain active after refreshes and restarts.

## Reset display

You can choose how reset times are displayed.

**Relative:**

```text
↻ 3h 18m
```

**Absolute:**

```text
↻ Today 8:40 PM
```

Longer resets automatically become values such as:

```text
↻ Tomorrow 9:15 AM
↻ Sep 8, 4:30 PM
```

The absolute time is calculated locally from the countdown returned by `ai-usagebar`.

## Built-in update checker

The plugin checks the public GitHub version periodically and shows its current version in the dropdown.

When current:

```text
Version 1.3.0
✓ Up to date
```

When a newer version exists:

```text
Version 1.3.0
⬆️ Update available: 1.4.0
```

Click **Update available** to replace the local plugin with the newest version from this repository.

There is also a **Check for updates now** action.

To avoid unnecessary network requests, automatic update checks are cached for approximately **6 hours**.

## Optional automatic updates

Automatic updates are **off by default**.

Enable **Automatic updates** in the dropdown if you want the plugin to install a newer version automatically when a scheduled update check finds one.

The updater only downloads this repository's public `ai-limits.1m.sh` file, verifies that it contains a SwiftBar version and a Bash shebang, then replaces the currently running plugin file.

You can turn automatic updates off again at any time.

## Provider detection

The plugin detects a provider only when `ai-usagebar` returns at least one real numeric usage metric for it.

| Setup | Behavior in Full / Compact / Minimal modes |
|---|---|
| Claude + Codex | Shows both providers separated by `•` |
| Claude only | Shows only Claude |
| Codex only | Shows only Codex |
| Neither available | Shows `⚠️ No Claude/Codex usage detected` |

Missing windows are hidden individually.

## Requirements

- macOS
- [SwiftBar](https://github.com/swiftbar/SwiftBar)
- [ai-usagebar](https://github.com/akitaonrails/ai-usagebar)
- Claude Code and/or Codex CLI authenticated, depending on what you use

You do **not** need both Claude Code and Codex installed.

## Do I need to use Claude or Codex in Terminal?

**No.** You do not need to keep Terminal open or do your day-to-day work there.

The plugin only needs the provider's official CLI to be installed and authenticated at least once because `ai-usagebar` reuses those local credentials.

Claude Code:

```bash
claude
```

Codex:

```bash
codex
```

After signing in, you can close Terminal.

| What you use | What you need to authenticate |
|---|---|
| Claude only | `claude` once |
| Codex only | `codex` once |
| Claude + Codex | both once |

## Quick install

### 1. Install SwiftBar

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

Then:

```bash
cargo install ai-usagebar
```

### 3. Authenticate the provider(s) you use

```bash
claude
codex
```

Run only the CLI(s) you actually use.

### 4. Install this plugin

```bash
curl -fsSL https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/install.sh | bash
```

The installer places the plugin at:

```text
~/Documents/SwiftBar/ai-limits.1m.sh
```

## Manual install / update

```bash
mkdir -p ~/Documents/SwiftBar
curl -fsSL \
  https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/ai-limits.1m.sh \
  -o ~/Documents/SwiftBar/ai-limits.1m.sh
chmod +x ~/Documents/SwiftBar/ai-limits.1m.sh
open -a SwiftBar
```

## Dropdown example

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

Metrics
Claude
  ✓ 5-hour
  ✓ Weekly
  ✓ Fable
Codex
  ✓ 5-hour
  ✓ Weekly

Reset display
✓ Relative — 3h 18m
  Absolute — Today 8:40 PM

Updates
Version 1.3.0
✓ Up to date
☐ Automatic updates
Check for updates now

↻ Refresh now
```

## Understanding the labels

| Label | Meaning |
|---|---|
| `Claude 5h` | Claude Code rolling 5-hour window |
| `W` after Claude | Claude weekly usage |
| `Fable` | Claude model-specific weekly window, when exposed by the account |
| `Codex 5h` | Codex rolling 5-hour window |
| `W` after Codex | Codex weekly usage |

Percentages are **used**, not remaining.

## Refresh interval

The included plugin is named:

```text
ai-limits.1m.sh
```

SwiftBar interprets `1m` as **refresh every 1 minute**.

## Moving the item in the menu bar

Hold **Command (⌘)** and drag the item left or right.

## Custom ai-usagebar location

The plugin checks:

```text
~/.cargo/bin/ai-usagebar
/opt/homebrew/bin/ai-usagebar
/usr/local/bin/ai-usagebar
PATH
```

You can also set:

```bash
export AI_USAGEBAR="/custom/path/to/ai-usagebar"
```

## Troubleshooting

### `ai-usagebar was not found`

```bash
which ai-usagebar
```

If missing:

```bash
cargo install ai-usagebar
```

### Claude values are missing

```bash
claude
```

Then test:

```bash
~/.cargo/bin/ai-usagebar --vendor anthropic --format '{session_pct} {weekly_pct} {scoped_model} {scoped_pct}' --json
```

### Codex values are missing

```bash
codex
```

Then test:

```bash
~/.cargo/bin/ai-usagebar --vendor openai --format '{session_pct} {weekly_pct}' --json
```

### Fable is missing

The model-specific row comes from `ai-usagebar`'s scoped-model fields. If Claude does not expose a model-specific weekly window for the account, that row is hidden.

### Update status unavailable

The plugin could not reach the raw GitHub file during the latest check. Normal Claude/Codex usage display continues to work. Choose **Check for updates now** later.

## How it works

This project is a display layer over `ai-usagebar`.

Claude fields used:

```text
{session_pct}
{session_reset}
{weekly_pct}
{weekly_reset}
{scoped_model}
{scoped_pct}
{scoped_reset}
```

Codex fields used:

```text
{session_pct}
{session_reset}
{weekly_pct}
{weekly_reset}
```

The plugin detects available windows, applies your saved metric/display preferences, formats reset times, and renders the result through SwiftBar.

Display mode, metric selections, reset style, and automatic-update preference are stored locally in SwiftBar's plugin data directory (with a user Library fallback).

No Claude or Codex credentials are stored by this plugin.

## Credits

This project depends on:

- [ai-usagebar](https://github.com/akitaonrails/ai-usagebar) by AkitaOnRails
- [SwiftBar](https://github.com/swiftbar/SwiftBar)

Both upstream projects are MIT licensed.

## Privacy

This plugin does not maintain its own credential store or usage database.

It invokes your locally installed `ai-usagebar` binary and displays its returned usage values through SwiftBar. The update checker contacts this repository's public raw GitHub URL to compare plugin versions.

Review the upstream projects for their authentication and network behavior.

## Contributing

Issues and pull requests are welcome.

## License

MIT © 2026 Roberto Pirozzi
