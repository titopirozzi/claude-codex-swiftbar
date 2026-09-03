# Claude + Codex Usage Monitor

See **Claude Code** and **OpenAI Codex** usage limits without opening separate apps.

This project now supports both major desktop platforms:

| Platform | UI | Status |
|---|---|---|
| 🍎 **macOS** | SwiftBar menu-bar plugin | Supported |
| 🪟 **Windows** | System-tray app + optional floating top bar | Supported |

The repository originally started as a macOS SwiftBar plugin, which is why the repository name still contains `swiftbar`.

## Choose your platform

### 🍎 macOS

Uses [SwiftBar](https://github.com/swiftbar/SwiftBar) to place live usage directly in the macOS menu bar:

```text
⚡️ Claude 5h 64% · W 60% · Fable 48%  •  🤖 Codex 5h 13% · W 73%
```

Jump to [macOS installation](#macos-installation).

### 🪟 Windows

Windows does not have the same extensible text-based menu bar as macOS. The Windows version therefore runs in the **system tray near the clock**.

It also includes an optional **floating top bar** that approximates the macOS experience and can keep the usage string visible horizontally near the top-right of the screen.

Quick install from PowerShell:

```powershell
irm https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/windows/install.ps1 | iex
```

Full Windows documentation: [windows/README.md](windows/README.md)

---

# Shared features

Both frontends are built around [ai-usagebar](https://github.com/akitaonrails/ai-usagebar) and support the same core usage data:

- Claude Code rolling 5-hour usage
- Claude weekly usage
- Claude model-specific weekly usage such as **Fable**, when available
- Codex rolling 5-hour usage
- Codex weekly usage
- reset countdowns
- per-metric visibility controls
- provider detection
- update checking
- optional automatic updates

You can use **Claude only**, **Codex only**, or **both**.

If a provider or usage window is unavailable, it is hidden rather than replaced with a misleading `0%`.

# Display modes

The project includes five display modes:

| Mode | Example | Best for |
|---|---|---|
| **Full — Claude + Codex** | `⚡ Claude 5h 64% · W 60% · Fable 48% • 🤖 Codex 5h 13% · W 73%` | Large monitors |
| **Compact — Claude + Codex** | `⚡ Claude 5h64·W60·F48% • 🤖 Codex 5h13·W73%` | Smaller screens |
| **Minimal — icons + numbers** | `⚡ 64·60·48 • 🤖 13·73` | Very limited space |
| **Claude only** | `⚡ Claude 5h 64% · W 60% · Fable 48%` | Claude-focused users |
| **Codex only** | `🤖 Codex 5h 13% · W 73%` | Codex-focused users |

# Choose exactly which metrics appear

Claude:

- 5-hour
- Weekly
- model-specific / Fable

Codex:

- 5-hour
- Weekly

For example, you can show only weekly usage:

```text
⚡ Claude W 60%  •  🤖 Codex W 73%
```

# Reset display

Choose between a countdown:

```text
↻ 3h 18m
```

or a local clock time:

```text
↻ Today 8:40 PM
```

# Updates

Both frontends include update checking.

Automatic updates are **off by default** and can be enabled from the app/plugin menu.

---

# macOS installation

## Requirements

- macOS
- [SwiftBar](https://github.com/swiftbar/SwiftBar)
- [ai-usagebar](https://github.com/akitaonrails/ai-usagebar)
- Claude Code and/or Codex authenticated locally

You do **not** need both providers installed.

## 1. Install SwiftBar

```bash
brew install swiftbar
```

Open SwiftBar once and choose a Plugin Folder. The examples use:

```text
~/Documents/SwiftBar
```

## 2. Install ai-usagebar

If Rust/Cargo is not installed:

```bash
curl https://sh.rustup.rs -sSf | sh
source "$HOME/.cargo/env"
```

Then:

```bash
cargo install ai-usagebar
```

## 3. Authenticate the provider(s) you use

Claude:

```bash
claude
```

Codex:

```bash
codex
```

The CLI only needs to be installed/authenticated; you do not need to keep Terminal open or do your day-to-day work there.

## 4. Install the SwiftBar plugin

```bash
curl -fsSL https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/install.sh | bash
```

The plugin is installed as:

```text
~/Documents/SwiftBar/ai-limits.1m.sh
```

`1m` tells SwiftBar to refresh every minute.

## macOS dropdown

Example:

```text
⚡️ CLAUDE CODE
🟠 5-hour    64%  ██████░░░░   ↻ 3h 05m
🟠 Weekly    60%  ██████░░░░   ↻ 4d 17h
🟢 Fable     48%  ████░░░░░░   ↻ 4d 17h

🤖 CODEX
🟢 5-hour    13%  █░░░░░░░░░   ↻ 2h 36m
🟠 Weekly    73%  ███████░░░   ↻ 3d 17h

Display >
Metrics >
Reset display >
Updates >
Refresh now
```

Hold **Command (⌘)** and drag the SwiftBar item to reposition it in the macOS menu bar.

---

# Windows installation

The Windows frontend uses PowerShell + Windows Forms `NotifyIcon`, so it does not require Electron, Python, or Node for the UI.

## Quick install

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/windows/install.ps1 | iex
```

The installer downloads the tray app, creates a user Startup shortcut, looks for `ai-usagebar.exe`, and attempts to install the required Rust tooling when possible.

`ai-usagebar` supports native Windows execution, but its upstream project currently documents building the Windows binary with a Rust toolchain. If the installer cannot finish that build automatically, it will tell you to run:

```powershell
cargo install ai-usagebar
```

Then authenticate Claude and/or Codex once:

```powershell
claude
codex
```

## Windows UI

The app lives in the **system tray near the clock**.

Click the icon to open:

```text
Claude Code >
Codex >
Display >
Metrics >
Reset display >
Show floating top bar (macOS-style)
Updates >
Refresh now
Open GitHub
Exit
```

## Optional floating top bar

Windows does not reserve a macOS-style menu-bar area for arbitrary third-party text.

If you want the usage visible all the time, enable:

```text
Show floating top bar (macOS-style)
```

It creates a small borderless always-on-top readout near the upper-right corner:

```text
⚡ Claude 5h 64% · W 60% · Fable 48%  •  🤖 Codex 5h 13% · W 73%
```

This does **not** modify the Windows taskbar; it is an optional overlay and can be disabled at any time.

Full documentation: [windows/README.md](windows/README.md)

## Windows uninstall

```powershell
irm https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/windows/uninstall.ps1 | iex
```

---

# Authentication

The frontends do not maintain their own Claude/Codex credential store.

They call the locally installed `ai-usagebar` binary. `ai-usagebar` reuses the official CLI credentials for Claude and Codex.

On Windows those credentials are read from the Windows user profile, including paths such as:

```text
%USERPROFILE%\.claude\.credentials.json
%USERPROFILE%\.codex\auth.json
```

# How it works

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

The frontend detects available windows, applies the user's display/metric settings, formats resets, and renders the result in the platform-specific UI.

# Privacy

This project does not maintain its own credential database or usage history database.

It invokes `ai-usagebar` locally and displays its returned usage values. Update checking contacts this repository's public raw GitHub files.

Review `ai-usagebar` for the exact provider authentication/network behavior.

# Credits

- [ai-usagebar](https://github.com/akitaonrails/ai-usagebar) by AkitaOnRails
- [SwiftBar](https://github.com/swiftbar/SwiftBar) for the macOS frontend

Both upstream projects are MIT licensed.

# Contributing

Issues and pull requests are welcome.

# License

MIT © 2026 Roberto Pirozzi
