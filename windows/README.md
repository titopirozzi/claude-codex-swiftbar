# Claude + Codex Usage — Windows

Windows does not have a native macOS-style menu bar where arbitrary apps can permanently place live text. The closest native equivalent is the **system tray** near the clock.

This project therefore uses a Windows tray app, with an optional **floating top bar** for people who want the Claude/Codex percentages visible horizontally all the time.

## What you get

The Windows app supports the same core ideas as the macOS SwiftBar version:

- Claude Code 5-hour usage
- Claude weekly usage
- Claude model-specific usage such as Fable, when available
- Codex 5-hour usage
- Codex weekly usage
- Full / Compact / Minimal display modes
- Claude only / Codex only modes
- per-metric visibility toggles
- relative or absolute reset times
- update checker
- optional automatic updates
- refresh every minute
- start automatically with Windows

The normal Windows UI lives in the **system tray**.

Hover over the icon to see a compact usage summary. Click the icon to open the complete menu.

## Optional macOS-style floating bar

Open the tray menu and enable:

```text
Show floating top bar (macOS-style)
```

This creates a small always-on-top horizontal readout near the upper-right corner of the primary monitor, for example:

```text
⚡ Claude 5h 64% · W 60% · Fable 48%  •  🤖 Codex 5h 13% · W 73%
```

It is optional and off by default because, unlike the macOS menu bar, Windows does not reserve a dedicated area for third-party text widgets.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or newer
- `ai-usagebar` built for Windows
- Claude Code and/or Codex authenticated locally

`ai-usagebar` has native Windows support for its executable and TUI. On Windows it reads Claude/Codex credentials from the user profile, including:

```text
%USERPROFILE%\.claude\.credentials.json
%USERPROFILE%\.codex\auth.json
```

The official Claude/Codex CLI only needs to be run and authenticated once.

## Quick install

Open **PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/windows/install.ps1 | iex
```

The installer:

1. downloads the tray app to `%LOCALAPPDATA%\ClaudeCodexUsage`
2. looks for `ai-usagebar.exe`
3. tries to install Rust with `winget` if Rust/Cargo is missing
4. runs `cargo install ai-usagebar` when possible
5. creates a Startup shortcut so the tray app launches when you sign in
6. starts the app immediately when dependencies are ready

If the Rust/MSVC build prerequisites are incomplete, the installer leaves the tray app installed and tells you to finish `ai-usagebar` with:

```powershell
cargo install ai-usagebar
```

Then run the installer again.

## Authenticate Claude and/or Codex

Claude:

```powershell
claude
```

Codex:

```powershell
codex
```

You only need the provider(s) you actually use.

After authentication, you can close PowerShell. The usage app continues from the tray.

## Tray menu

The menu contains approximately:

```text
⚡ Claude 5h 64% · W 60% · Fable 48% • 🤖 Codex 13% · W 73%

⚡ Claude Code >
  🟠 5-hour   64%  ██████░░░░  ↻ 3h 05m
  🟠 Weekly   60%  ██████░░░░  ↻ 4d 17h
  🟢 Fable    48%  ████░░░░░░  ↻ 4d 17h

🤖 Codex >
  🟢 5-hour   13%  █░░░░░░░░░  ↻ 2h 36m
  🟠 Weekly   73%  ███████░░░  ↻ 3d 17h

Display >
Metrics >
Reset display >
Show floating top bar (macOS-style)
Updates >
Refresh now
Open GitHub
Exit
```

## Display modes

- **Full — Claude + Codex**
- **Compact — Claude + Codex**
- **Minimal — icons + numbers**
- **Claude only**
- **Codex only**

If only one provider is authenticated, the app automatically hides the missing provider.

## Metric selection

Claude metrics can be toggled independently:

- 5-hour
- Weekly
- model-specific / Fable

Codex metrics:

- 5-hour
- Weekly

For example, showing only the weekly limits gives a much smaller status string.

## Reset display

Choose either:

```text
Relative — 3h 18m
```

or:

```text
Absolute — Today 8:40 PM
```

Absolute time is calculated locally from the reset countdown.

## Updates

The Windows tray app has its own version number and checks this repository approximately every six hours.

Automatic updates are disabled by default. They can be enabled from the **Updates** submenu.

Only `windows/ClaudeCodexTray.ps1` is replaced by the self-updater.

## Start with Windows

The installer creates this user Startup shortcut:

```text
Claude Codex Usage.lnk
```

No administrator privileges are required for the tray app itself.

## Uninstall

Run:

```powershell
irm https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/windows/uninstall.ps1 | iex
```

The uninstaller removes the tray app, its settings, and its Startup shortcut.

It does **not** uninstall Claude Code, Codex, Rust, or `ai-usagebar`.

## Privacy

The Windows frontend does not store Claude or Codex credentials.

It calls the locally installed `ai-usagebar.exe`, displays the returned usage values, and contacts this public GitHub repository for update checks.

## Technical note

The Windows frontend is implemented with PowerShell and Windows Forms `NotifyIcon`, so it can run without Python, Node, Electron, or a separate desktop runtime.

The floating top bar is an optional borderless always-on-top Windows Forms window. It is an approximation of the persistent text experience macOS provides in its menu bar; it is not a modification of the Windows taskbar.
