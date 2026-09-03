#requires -Version 5.1

$ErrorActionPreference = 'Stop'

$RawBase = 'https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/windows'
$InstallDir = Join-Path $env:LOCALAPPDATA 'ClaudeCodexUsage'
$ScriptPath = Join-Path $InstallDir 'ClaudeCodexTray.ps1'
$StartupDir = [Environment]::GetFolderPath('Startup')
$ShortcutPath = Join-Path $StartupDir 'Claude Codex Usage.lnk'

Write-Host ''
Write-Host 'Claude + Codex Usage for Windows' -ForegroundColor Cyan
Write-Host '----------------------------------'

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Write-Host 'Downloading Windows tray app...'
Invoke-WebRequest -UseBasicParsing -Uri "$RawBase/ClaudeCodexTray.ps1" -OutFile $ScriptPath

function Resolve-AiUsageBar {
    $cmd = Get-Command ai-usagebar.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidate = Join-Path $env:USERPROFILE '.cargo\bin\ai-usagebar.exe'
    if (Test-Path $candidate) { return $candidate }
    return $null
}

$ai = Resolve-AiUsageBar
if (-not $ai) {
    Write-Host ''
    Write-Host 'ai-usagebar is not installed yet.' -ForegroundColor Yellow

    $cargo = Get-Command cargo.exe -ErrorAction SilentlyContinue
    if (-not $cargo) {
        $cargoCandidate = Join-Path $env:USERPROFILE '.cargo\bin\cargo.exe'
        if (Test-Path $cargoCandidate) { $cargo = Get-Item $cargoCandidate }
    }

    if (-not $cargo) {
        $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($winget) {
            Write-Host 'Installing Rust with winget...'
            winget install --id Rustlang.Rustup -e --accept-package-agreements --accept-source-agreements
            $cargoCandidate = Join-Path $env:USERPROFILE '.cargo\bin\cargo.exe'
            if (Test-Path $cargoCandidate) { $cargo = Get-Item $cargoCandidate }
        }
    }

    if ($cargo) {
        Write-Host 'Building/installing ai-usagebar for Windows. This can take a few minutes...'
        try {
            & $cargo.FullName install ai-usagebar
        } catch {}
        $ai = Resolve-AiUsageBar
    }
}

if (-not $ai) {
    Write-Host ''
    Write-Host 'The tray app was installed, but ai-usagebar still needs to be built.' -ForegroundColor Yellow
    Write-Host 'Install the Windows Rust/MSVC build prerequisites, then run:'
    Write-Host '  cargo install ai-usagebar' -ForegroundColor White
    Write-Host ''
    Write-Host 'After that, run this installer again or launch:'
    Write-Host "  $ScriptPath"
} else {
    Write-Host "Found ai-usagebar: $ai" -ForegroundColor Green
}

Write-Host 'Creating Windows startup shortcut...'
$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($ShortcutPath)
$shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
$shortcut.WorkingDirectory = $InstallDir
$shortcut.Description = 'Claude + Codex Usage Monitor'
$shortcut.Save()

$claudeCreds = Join-Path $env:USERPROFILE '.claude\.credentials.json'
$codexCreds = Join-Path $env:USERPROFILE '.codex\auth.json'

Write-Host ''
if (-not (Test-Path $claudeCreds) -and -not (Test-Path $codexCreds)) {
    Write-Host 'No Claude/Codex CLI credentials were detected yet.' -ForegroundColor Yellow
    Write-Host 'Run the provider(s) you use once and sign in:'
    Write-Host '  claude'
    Write-Host '  codex'
    Write-Host ''
}

if ($ai) {
    Write-Host 'Starting Claude + Codex Usage...' -ForegroundColor Green
    $args = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
    Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WindowStyle Hidden
}

Write-Host ''
Write-Host "Installed to: $InstallDir"
Write-Host 'The app starts automatically when you sign in to Windows.'
Write-Host 'Look for its icon in the system tray near the clock.'
Write-Host ''
Write-Host 'Tip: open the tray menu and enable "Show floating top bar (macOS-style)"'
Write-Host 'if you want the usage numbers visible horizontally at the top of the screen.'
