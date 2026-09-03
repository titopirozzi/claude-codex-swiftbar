#requires -Version 5.1

$ErrorActionPreference = 'SilentlyContinue'

$InstallDir = Join-Path $env:LOCALAPPDATA 'ClaudeCodexUsage'
$DataDir = Join-Path $env:APPDATA 'ClaudeCodexUsage'
$StartupDir = [Environment]::GetFolderPath('Startup')
$ShortcutPath = Join-Path $StartupDir 'Claude Codex Usage.lnk'

Get-CimInstance Win32_Process |
    Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -like '*ClaudeCodexTray.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Remove-Item -Force $ShortcutPath
Remove-Item -Recurse -Force $InstallDir
Remove-Item -Recurse -Force $DataDir

Write-Host 'Claude + Codex Usage for Windows was removed.'
Write-Host 'ai-usagebar, Claude Code, Codex, and Rust were left untouched.'
