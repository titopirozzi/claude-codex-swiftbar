#requires -Version 5.1

$ErrorActionPreference = 'SilentlyContinue'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$WINDOWS_VERSION = '1.0.0'
$REPO_URL = 'https://github.com/titopirozzi/claude-codex-swiftbar'
$REMOTE_SCRIPT_URL = 'https://raw.githubusercontent.com/titopirozzi/claude-codex-swiftbar/main/windows/ClaudeCodexTray.ps1'
$UPDATE_CHECK_INTERVAL_SECONDS = 21600

$DataDir = Join-Path $env:APPDATA 'ClaudeCodexUsage'
$ConfigPath = Join-Path $DataDir 'config.json'
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

function New-DefaultConfig {
    return [ordered]@{
        mode = 'full'
        resetStyle = 'relative'
        autoUpdate = $false
        floatingBar = $false
        lastUpdateCheck = ''
        remoteVersion = ''
        metrics = [ordered]@{
            claude5h = $true
            claudeWeekly = $true
            claudeModel = $true
            codex5h = $true
            codexWeekly = $true
        }
    }
}

function Load-Config {
    $cfg = New-DefaultConfig
    if (Test-Path $ConfigPath) {
        try {
            $saved = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
            if ($saved.mode) { $cfg.mode = [string]$saved.mode }
            if ($saved.resetStyle) { $cfg.resetStyle = [string]$saved.resetStyle }
            if ($null -ne $saved.autoUpdate) { $cfg.autoUpdate = [bool]$saved.autoUpdate }
            if ($null -ne $saved.floatingBar) { $cfg.floatingBar = [bool]$saved.floatingBar }
            if ($saved.lastUpdateCheck) { $cfg.lastUpdateCheck = [string]$saved.lastUpdateCheck }
            if ($saved.remoteVersion) { $cfg.remoteVersion = [string]$saved.remoteVersion }
            if ($saved.metrics) {
                foreach ($name in @('claude5h','claudeWeekly','claudeModel','codex5h','codexWeekly')) {
                    if ($null -ne $saved.metrics.$name) { $cfg.metrics[$name] = [bool]$saved.metrics.$name }
                }
            }
        } catch {}
    }
    if ($cfg.mode -notin @('full','compact','minimal','claude','codex')) { $cfg.mode = 'full' }
    if ($cfg.resetStyle -notin @('relative','absolute')) { $cfg.resetStyle = 'relative' }
    return $cfg
}

function Save-Config {
    try {
        $script:Config | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -Path $ConfigPath
    } catch {}
}

$script:Config = Load-Config

function Resolve-AiUsageBar {
    $cmd = Get-Command ai-usagebar.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmd = Get-Command ai-usagebar -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    foreach ($candidate in @(
        (Join-Path $env:USERPROFILE '.cargo\bin\ai-usagebar.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\ai-usagebar\ai-usagebar.exe')
    )) {
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

$script:AiUsageBar = Resolve-AiUsageBar

function Get-FieldArray([string]$Vendor, [string]$Format) {
    if (-not $script:AiUsageBar) { return @() }
    try {
        $raw = (& $script:AiUsageBar --vendor $Vendor --format $Format --json 2>$null | Out-String).Trim()
        if (-not $raw) { return @() }
        $obj = $raw | ConvertFrom-Json
        $text = [regex]::Replace([string]$obj.text, '<[^>]+>', '')
        return $text.Split([string[]]@(';;'), [System.StringSplitOptions]::None)
    } catch {
        return @()
    }
}

function Field([object[]]$Values, [int]$Index) {
    if ($Values -and $Values.Count -gt $Index) { return [string]$Values[$Index] }
    return ''
}

function Is-Pct([string]$Value) {
    return ($Value -match '^\d+(\.\d+)?$')
}

function Safe-Pct([string]$Value) {
    if (-not (Is-Pct $Value)) { return 0 }
    $n = [int][math]::Floor([double]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture))
    if ($n -lt 0) { $n = 0 }
    if ($n -gt 100) { $n = 100 }
    return $n
}

function Usage-Bar([string]$Value) {
    $pct = Safe-Pct $Value
    $filled = [math]::Floor($pct / 10)
    return ('█' * $filled) + ('░' * (10 - $filled))
}

function Status-Icon([string]$Value) {
    $pct = Safe-Pct $Value
    if ($pct -ge 80) { return '🔴' }
    if ($pct -ge 60) { return '🟠' }
    return '🟢'
}

function Refresh-Usage {
    $c = Get-FieldArray 'anthropic' '{session_pct};;{session_reset};;{weekly_pct};;{weekly_reset};;{scoped_model};;{scoped_pct};;{scoped_reset}'
    $o = Get-FieldArray 'openai' '{session_pct};;{session_reset};;{weekly_pct};;{weekly_reset}'

    $script:Usage = [ordered]@{
        claude = [ordered]@{
            sessionPct = Field $c 0
            sessionReset = Field $c 1
            weeklyPct = Field $c 2
            weeklyReset = Field $c 3
            modelName = Field $c 4
            modelPct = Field $c 5
            modelReset = Field $c 6
        }
        codex = [ordered]@{
            sessionPct = Field $o 0
            sessionReset = Field $o 1
            weeklyPct = Field $o 2
            weeklyReset = Field $o 3
        }
    }

    $script:ClaudeAvailable = (Is-Pct $script:Usage.claude.sessionPct) -or (Is-Pct $script:Usage.claude.weeklyPct) -or (Is-Pct $script:Usage.claude.modelPct)
    $script:CodexAvailable = (Is-Pct $script:Usage.codex.sessionPct) -or (Is-Pct $script:Usage.codex.weeklyPct)
}

function Format-Reset([string]$Reset) {
    if (-not $Reset) { return '—' }
    if ($script:Config.resetStyle -eq 'relative') { return $Reset }

    try {
        $days = 0; $hours = 0; $minutes = 0; $seconds = 0
        if ($Reset -match '(\d+)\s*d') { $days = [int]$Matches[1] }
        if ($Reset -match '(\d+)\s*h') { $hours = [int]$Matches[1] }
        if ($Reset -match '(\d+)\s*m') { $minutes = [int]$Matches[1] }
        if ($Reset -match '(\d+)\s*s') { $seconds = [int]$Matches[1] }
        if (($days + $hours + $minutes + $seconds) -eq 0) { return $Reset }

        $target = (Get-Date).AddDays($days).AddHours($hours).AddMinutes($minutes).AddSeconds($seconds)
        $today = (Get-Date).Date
        if ($target.Date -eq $today) { return 'Today ' + $target.ToString('h:mm tt') }
        if ($target.Date -eq $today.AddDays(1)) { return 'Tomorrow ' + $target.ToString('h:mm tt') }
        return $target.ToString('MMM d, h:mm tt')
    } catch {
        return $Reset
    }
}

function Metric-Enabled([string]$Name) {
    return [bool]$script:Config.metrics[$Name]
}

function Claude-Full {
    $parts = New-Object System.Collections.Generic.List[string]
    if ((Metric-Enabled 'claude5h') -and (Is-Pct $script:Usage.claude.sessionPct)) { $parts.Add("5h $($script:Usage.claude.sessionPct)%") }
    if ((Metric-Enabled 'claudeWeekly') -and (Is-Pct $script:Usage.claude.weeklyPct)) { $parts.Add("W $($script:Usage.claude.weeklyPct)%") }
    if ((Metric-Enabled 'claudeModel') -and $script:Usage.claude.modelName -and (Is-Pct $script:Usage.claude.modelPct)) { $parts.Add("$($script:Usage.claude.modelName) $($script:Usage.claude.modelPct)%") }
    if ($parts.Count -eq 0) { return '⚡ Claude' }
    return '⚡ Claude ' + ($parts -join ' · ')
}

function Codex-Full {
    $parts = New-Object System.Collections.Generic.List[string]
    if ((Metric-Enabled 'codex5h') -and (Is-Pct $script:Usage.codex.sessionPct)) { $parts.Add("5h $($script:Usage.codex.sessionPct)%") }
    if ((Metric-Enabled 'codexWeekly') -and (Is-Pct $script:Usage.codex.weeklyPct)) { $parts.Add("W $($script:Usage.codex.weeklyPct)%") }
    if ($parts.Count -eq 0) { return '🤖 Codex' }
    return '🤖 Codex ' + ($parts -join ' · ')
}

function Claude-Compact {
    $parts = New-Object System.Collections.Generic.List[string]
    if ((Metric-Enabled 'claude5h') -and (Is-Pct $script:Usage.claude.sessionPct)) { $parts.Add("5h$($script:Usage.claude.sessionPct)") }
    if ((Metric-Enabled 'claudeWeekly') -and (Is-Pct $script:Usage.claude.weeklyPct)) { $parts.Add("W$($script:Usage.claude.weeklyPct)") }
    if ((Metric-Enabled 'claudeModel') -and $script:Usage.claude.modelName -and (Is-Pct $script:Usage.claude.modelPct)) { $parts.Add("$($script:Usage.claude.modelName.Substring(0,1))$($script:Usage.claude.modelPct)") }
    return '⚡ Claude ' + ($parts -join '·') + '%'
}

function Codex-Compact {
    $parts = New-Object System.Collections.Generic.List[string]
    if ((Metric-Enabled 'codex5h') -and (Is-Pct $script:Usage.codex.sessionPct)) { $parts.Add("5h$($script:Usage.codex.sessionPct)") }
    if ((Metric-Enabled 'codexWeekly') -and (Is-Pct $script:Usage.codex.weeklyPct)) { $parts.Add("W$($script:Usage.codex.weeklyPct)") }
    return '🤖 Codex ' + ($parts -join '·') + '%'
}

function Claude-Minimal {
    $parts = New-Object System.Collections.Generic.List[string]
    if ((Metric-Enabled 'claude5h') -and (Is-Pct $script:Usage.claude.sessionPct)) { $parts.Add($script:Usage.claude.sessionPct) }
    if ((Metric-Enabled 'claudeWeekly') -and (Is-Pct $script:Usage.claude.weeklyPct)) { $parts.Add($script:Usage.claude.weeklyPct) }
    if ((Metric-Enabled 'claudeModel') -and (Is-Pct $script:Usage.claude.modelPct)) { $parts.Add($script:Usage.claude.modelPct) }
    return '⚡ ' + ($parts -join '·')
}

function Codex-Minimal {
    $parts = New-Object System.Collections.Generic.List[string]
    if ((Metric-Enabled 'codex5h') -and (Is-Pct $script:Usage.codex.sessionPct)) { $parts.Add($script:Usage.codex.sessionPct) }
    if ((Metric-Enabled 'codexWeekly') -and (Is-Pct $script:Usage.codex.weeklyPct)) { $parts.Add($script:Usage.codex.weeklyPct) }
    return '🤖 ' + ($parts -join '·')
}

function Get-TopText {
    if (-not $script:ClaudeAvailable -and -not $script:CodexAvailable) { return 'AI usage unavailable' }

    switch ($script:Config.mode) {
        'claude' {
            if ($script:ClaudeAvailable) { return Claude-Full }
            return 'Claude usage unavailable'
        }
        'codex' {
            if ($script:CodexAvailable) { return Codex-Full }
            return 'Codex usage unavailable'
        }
        'compact' {
            $c = if ($script:ClaudeAvailable) { Claude-Compact } else { '' }
            $o = if ($script:CodexAvailable) { Codex-Compact } else { '' }
        }
        'minimal' {
            $c = if ($script:ClaudeAvailable) { Claude-Minimal } else { '' }
            $o = if ($script:CodexAvailable) { Codex-Minimal } else { '' }
        }
        default {
            $c = if ($script:ClaudeAvailable) { Claude-Full } else { '' }
            $o = if ($script:CodexAvailable) { Codex-Full } else { '' }
        }
    }

    if ($c -and $o) { return "$c  •  $o" }
    if ($c) { return $c }
    return $o
}

function New-MenuItem([string]$Text, [string]$Tag = '', [bool]$Checked = $false, [bool]$Enabled = $true) {
    $item = New-Object System.Windows.Forms.ToolStripMenuItem
    $item.Text = $Text
    $item.Tag = $Tag
    $item.Checked = $Checked
    $item.Enabled = $Enabled
    if ($Tag) { $item.Add_Click($script:MenuClickHandler) }
    return $item
}

function Add-UsageRow($Menu, [string]$Label, [string]$Pct, [string]$Reset) {
    if (-not (Is-Pct $Pct)) { return }
    $text = "$(Status-Icon $Pct) $Label  $Pct%  $(Usage-Bar $Pct)   ↻ $(Format-Reset $Reset)"
    $item = New-MenuItem $text '' $false $false
    $item.Font = New-Object System.Drawing.Font('Consolas', 9)
    [void]$Menu.DropDownItems.Add($item)
}

function Show-ProviderInMenu([string]$Provider) {
    if ($script:Config.mode -eq 'claude') { return $Provider -eq 'claude' }
    if ($script:Config.mode -eq 'codex') { return $Provider -eq 'codex' }
    return $true
}

function Get-RemoteVersion {
    try {
        $content = (Invoke-WebRequest -UseBasicParsing -Uri $REMOTE_SCRIPT_URL -TimeoutSec 6 -Headers @{'User-Agent'='ClaudeCodexUsageTray'}).Content
        if ($content -match "\`$WINDOWS_VERSION\s*=\s*['\"]([^'\"]+)['\"]") { return $Matches[1] }
    } catch {}
    return ''
}

function Test-NewerVersion([string]$Remote) {
    if (-not $Remote) { return $false }
    try { return ([version]$Remote -gt [version]$WINDOWS_VERSION) } catch { return $false }
}

function Check-ForUpdates([bool]$Force = $false) {
    $due = $Force
    if (-not $due) {
        try {
            if (-not $script:Config.lastUpdateCheck) { $due = $true }
            else {
                $last = [datetime]::Parse($script:Config.lastUpdateCheck)
                $due = (((Get-Date) - $last).TotalSeconds -ge $UPDATE_CHECK_INTERVAL_SECONDS)
            }
        } catch { $due = $true }
    }
    if (-not $due) { return }

    $remote = Get-RemoteVersion
    $script:Config.lastUpdateCheck = (Get-Date).ToString('o')
    $script:Config.remoteVersion = $remote
    Save-Config

    if ($script:Config.autoUpdate -and (Test-NewerVersion $remote)) {
        Update-Self
    }
}

function Update-Self {
    try {
        $temp = Join-Path $env:TEMP "ClaudeCodexTray.$PID.ps1"
        Invoke-WebRequest -UseBasicParsing -Uri $REMOTE_SCRIPT_URL -OutFile $temp -TimeoutSec 15 -Headers @{'User-Agent'='ClaudeCodexUsageTray'}
        $content = Get-Content -Raw -Path $temp
        if ($content -notmatch "\`$WINDOWS_VERSION\s*=\s*['\"]([^'\"]+)['\"]") { throw 'Downloaded file has no version.' }
        $remote = $Matches[1]
        if (-not (Test-NewerVersion $remote)) { Remove-Item $temp -Force; return }
        Copy-Item -Force $temp $PSCommandPath
        Remove-Item $temp -Force
        $args = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
        Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WindowStyle Hidden
        if ($script:NotifyIcon) { $script:NotifyIcon.Visible = $false }
        [System.Windows.Forms.Application]::Exit()
    } catch {
        if ($script:NotifyIcon) {
            $script:NotifyIcon.BalloonTipTitle = 'Claude + Codex Usage'
            $script:NotifyIcon.BalloonTipText = 'Update failed. Try again later.'
            $script:NotifyIcon.ShowBalloonTip(3000)
        }
    }
}

function Update-FloatingBar {
    if (-not $script:FloatingForm) { return }
    if (-not $script:Config.floatingBar) {
        $script:FloatingForm.Hide()
        return
    }

    $text = Get-TopText
    $script:FloatingLabel.Text = $text
    $script:FloatingLabel.AutoSize = $true
    $width = [math]::Min([math]::Max($script:FloatingLabel.PreferredWidth + 24, 180), 900)
    $script:FloatingForm.Size = New-Object System.Drawing.Size($width, 32)
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $script:FloatingForm.Location = New-Object System.Drawing.Point(($screen.Right - $width - 12), ($screen.Top + 8))
    if (-not $script:FloatingForm.Visible) { $script:FloatingForm.Show() }
}

function Build-Menu {
    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    $menu.Font = New-Object System.Drawing.Font('Segoe UI', 9)

    $headline = New-MenuItem (Get-TopText) '' $false $false
    $headline.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 9)
    [void]$menu.Items.Add($headline)
    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    if ((Show-ProviderInMenu 'claude') -and $script:ClaudeAvailable) {
        $claudeMenu = New-MenuItem '⚡ Claude Code'
        if ((Metric-Enabled 'claude5h')) { Add-UsageRow $claudeMenu '5-hour ' $script:Usage.claude.sessionPct $script:Usage.claude.sessionReset }
        if ((Metric-Enabled 'claudeWeekly')) { Add-UsageRow $claudeMenu 'Weekly ' $script:Usage.claude.weeklyPct $script:Usage.claude.weeklyReset }
        if ((Metric-Enabled 'claudeModel') -and $script:Usage.claude.modelName) { Add-UsageRow $claudeMenu $script:Usage.claude.modelName $script:Usage.claude.modelPct $script:Usage.claude.modelReset }
        [void]$menu.Items.Add($claudeMenu)
    }

    if ((Show-ProviderInMenu 'codex') -and $script:CodexAvailable) {
        $codexMenu = New-MenuItem '🤖 Codex'
        if ((Metric-Enabled 'codex5h')) { Add-UsageRow $codexMenu '5-hour ' $script:Usage.codex.sessionPct $script:Usage.codex.sessionReset }
        if ((Metric-Enabled 'codexWeekly')) { Add-UsageRow $codexMenu 'Weekly ' $script:Usage.codex.weeklyPct $script:Usage.codex.weeklyReset }
        [void]$menu.Items.Add($codexMenu)
    }

    if (-not $script:ClaudeAvailable -and -not $script:CodexAvailable) {
        [void]$menu.Items.Add((New-MenuItem 'No authenticated Claude/Codex usage detected' '' $false $false))
    }

    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    $display = New-MenuItem 'Display'
    foreach ($pair in @(
        @('full','Full — Claude + Codex'),
        @('compact','Compact — Claude + Codex'),
        @('minimal','Minimal — icons + numbers'),
        @('claude','Claude only'),
        @('codex','Codex only')
    )) {
        [void]$display.DropDownItems.Add((New-MenuItem $pair[1] "mode:$($pair[0])" ($script:Config.mode -eq $pair[0]) $true))
    }
    [void]$menu.Items.Add($display)

    $metrics = New-MenuItem 'Metrics'
    $cm = New-MenuItem 'Claude'
    [void]$cm.DropDownItems.Add((New-MenuItem '5-hour' 'metric:claude5h' (Metric-Enabled 'claude5h') $true))
    [void]$cm.DropDownItems.Add((New-MenuItem 'Weekly' 'metric:claudeWeekly' (Metric-Enabled 'claudeWeekly') $true))
    $modelLabel = if ($script:Usage.claude.modelName) { $script:Usage.claude.modelName } else { 'Model-specific' }
    [void]$cm.DropDownItems.Add((New-MenuItem $modelLabel 'metric:claudeModel' (Metric-Enabled 'claudeModel') $true))
    [void]$metrics.DropDownItems.Add($cm)

    $om = New-MenuItem 'Codex'
    [void]$om.DropDownItems.Add((New-MenuItem '5-hour' 'metric:codex5h' (Metric-Enabled 'codex5h') $true))
    [void]$om.DropDownItems.Add((New-MenuItem 'Weekly' 'metric:codexWeekly' (Metric-Enabled 'codexWeekly') $true))
    [void]$metrics.DropDownItems.Add($om)
    [void]$menu.Items.Add($metrics)

    $reset = New-MenuItem 'Reset display'
    [void]$reset.DropDownItems.Add((New-MenuItem 'Relative — 3h 18m' 'reset:relative' ($script:Config.resetStyle -eq 'relative') $true))
    [void]$reset.DropDownItems.Add((New-MenuItem 'Absolute — Today 8:40 PM' 'reset:absolute' ($script:Config.resetStyle -eq 'absolute') $true))
    [void]$menu.Items.Add($reset)

    [void]$menu.Items.Add((New-MenuItem 'Show floating top bar (macOS-style)' 'floating:toggle' ([bool]$script:Config.floatingBar) $true))

    $updates = New-MenuItem 'Updates'
    [void]$updates.DropDownItems.Add((New-MenuItem "Windows version $WINDOWS_VERSION" '' $false $false))
    $remote = [string]$script:Config.remoteVersion
    if (Test-NewerVersion $remote) {
        [void]$updates.DropDownItems.Add((New-MenuItem "⬆ Update available: $remote" 'update:install' $false $true))
    } elseif ($remote) {
        [void]$updates.DropDownItems.Add((New-MenuItem '✓ Up to date' '' $false $false))
    } else {
        [void]$updates.DropDownItems.Add((New-MenuItem 'Update status unavailable' '' $false $false))
    }
    [void]$updates.DropDownItems.Add((New-MenuItem 'Automatic updates' 'update:auto' ([bool]$script:Config.autoUpdate) $true))
    [void]$updates.DropDownItems.Add((New-MenuItem 'Check for updates now' 'update:check' $false $true))
    [void]$menu.Items.Add($updates)

    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    [void]$menu.Items.Add((New-MenuItem '↻ Refresh now' 'refresh' $false $true))
    [void]$menu.Items.Add((New-MenuItem 'Open GitHub' 'github' $false $true))
    [void]$menu.Items.Add((New-MenuItem 'Exit' 'exit' $false $true))

    return $menu
}

function Refresh-All {
    $script:AiUsageBar = Resolve-AiUsageBar
    Refresh-Usage
    Check-ForUpdates $false

    $top = Get-TopText
    $tip = if ($top.Length -gt 63) { $top.Substring(0, 60) + '...' } else { $top }
    $script:NotifyIcon.Text = $tip

    $old = $script:NotifyIcon.ContextMenuStrip
    $script:NotifyIcon.ContextMenuStrip = Build-Menu
    if ($old) { $old.Dispose() }
    Update-FloatingBar
}

$script:MenuClickHandler = {
    param($Sender, $EventArgs)
    $tag = [string]$Sender.Tag

    if ($tag -like 'mode:*') {
        $script:Config.mode = $tag.Substring(5)
        Save-Config
        Refresh-All
        return
    }
    if ($tag -like 'metric:*') {
        $name = $tag.Substring(7)
        $script:Config.metrics[$name] = -not [bool]$script:Config.metrics[$name]
        Save-Config
        Refresh-All
        return
    }
    if ($tag -like 'reset:*') {
        $script:Config.resetStyle = $tag.Substring(6)
        Save-Config
        Refresh-All
        return
    }

    switch ($tag) {
        'floating:toggle' {
            $script:Config.floatingBar = -not [bool]$script:Config.floatingBar
            Save-Config
            Refresh-All
        }
        'update:auto' {
            $script:Config.autoUpdate = -not [bool]$script:Config.autoUpdate
            Save-Config
            if ($script:Config.autoUpdate) { Check-ForUpdates $true }
            Refresh-All
        }
        'update:check' {
            Check-ForUpdates $true
            Refresh-All
        }
        'update:install' { Update-Self }
        'refresh' { Refresh-All }
        'github' { Start-Process $REPO_URL }
        'exit' {
            $script:NotifyIcon.Visible = $false
            if ($script:FloatingForm) { $script:FloatingForm.Close() }
            [System.Windows.Forms.Application]::Exit()
        }
    }
}

$script:NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:NotifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$script:NotifyIcon.Visible = $true
$script:NotifyIcon.Text = 'Claude + Codex Usage'

$script:FloatingForm = New-Object System.Windows.Forms.Form
$script:FloatingForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$script:FloatingForm.ShowInTaskbar = $false
$script:FloatingForm.TopMost = $true
$script:FloatingForm.BackColor = [System.Drawing.Color]::FromArgb(38,38,38)
$script:FloatingForm.Opacity = 0.94
$script:FloatingForm.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual

$script:FloatingLabel = New-Object System.Windows.Forms.Label
$script:FloatingLabel.ForeColor = [System.Drawing.Color]::White
$script:FloatingLabel.BackColor = [System.Drawing.Color]::Transparent
$script:FloatingLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Regular)
$script:FloatingLabel.Location = New-Object System.Drawing.Point(12, 7)
$script:FloatingLabel.AutoSize = $true
$script:FloatingForm.Controls.Add($script:FloatingLabel)

Refresh-All
$script:FloatingForm.ContextMenuStrip = $script:NotifyIcon.ContextMenuStrip
$script:FloatingLabel.ContextMenuStrip = $script:NotifyIcon.ContextMenuStrip

$script:NotifyIcon.Add_MouseClick({
    param($Sender, $EventArgs)
    if ($EventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $Sender.ContextMenuStrip.Show([System.Windows.Forms.Cursor]::Position)
    }
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 60000
$timer.Add_Tick({
    Refresh-All
    $script:FloatingForm.ContextMenuStrip = $script:NotifyIcon.ContextMenuStrip
    $script:FloatingLabel.ContextMenuStrip = $script:NotifyIcon.ContextMenuStrip
})
$timer.Start()

[System.Windows.Forms.Application]::Run()

$timer.Stop()
$timer.Dispose()
$script:NotifyIcon.Visible = $false
$script:NotifyIcon.Dispose()
if ($script:FloatingForm) { $script:FloatingForm.Dispose() }
