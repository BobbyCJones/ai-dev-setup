# cleanup-dev-tools-config.ps1
# TEMPORARY DEBUG ARTIFACT.
# Keep this script only while validating installer changes and machine reset
# behavior. It is not intended to be part of the long-term repo architecture.
#
# Removes configuration previously added by install-dev-tools.ps1 while leaving
# installed tools, auth state, and PowerShell modules in place.
#
# What it does:
# - Backs up affected config files to a timestamped folder
# - Removes legacy dev-tools blocks and current ai-dev-setup include blocks
# - Optionally removes %USERPROFILE%\.ai-dev-setup managed files
# - Optionally removes agent template files if they exactly match agent-tools.md
# - Optionally removes the repo-owned global mise fragment
# - Optionally removes %APPDATA%\mise\config.toml
# - Optionally removes %LOCALAPPDATA%\mise\shims from the user PATH
# - Unsets delta-related git global config keys only when they still match
#   this repo's recommended values
#
# Safe to run multiple times.

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$RemoveManagedConfigDir,
    [switch]$RemoveAgentTemplates,
    [switch]$RemoveMiseFragment,
    [switch]$RemoveMiseConfig,
    [switch]$RemoveMiseShimsPath,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step($Message) {
    Write-Host "`n>> $Message" -ForegroundColor Cyan
}

function Write-Ok($Message) {
    Write-Host "   [ok] $Message" -ForegroundColor Green
}

function Write-Skip($Message) {
    Write-Host "   [--] $Message" -ForegroundColor DarkGray
}

function Write-Warn($Message) {
    Write-Host "   [??] $Message" -ForegroundColor Yellow
}

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Get-DefaultTextEncoding {
    param([Parameter(Mandatory = $true)][string]$Path)

    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($extension -eq ".ps1" -or $extension -eq ".md") {
        return [System.Text.UTF8Encoding]::new($true)
    }

    return [System.Text.UTF8Encoding]::new($false)
}

function Get-PreferredNewLine {
    param([Parameter(Mandatory = $true)][string]$Path)

    $leaf = Split-Path -Leaf $Path
    if ($leaf -eq ".bashrc" -or [System.IO.Path]::GetExtension($Path).ToLowerInvariant() -eq ".bash") {
        return "`n"
    }

    return [System.Environment]::NewLine
}

function Get-TextFileState {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            Content  = ""
            Encoding = Get-DefaultTextEncoding -Path $Path
            NewLine  = Get-PreferredNewLine -Path $Path
        }
    }

    $reader = [System.IO.StreamReader]::new($Path, $true)
    try {
        $content = $reader.ReadToEnd()
        $encoding = $reader.CurrentEncoding
    } finally {
        $reader.Dispose()
    }

    $newlineMatch = [regex]::Match($content, "`r`n|`n|`r")
    $newLine = if ($newlineMatch.Success) { $newlineMatch.Value } else { Get-PreferredNewLine -Path $Path }

    return [pscustomobject]@{
        Content  = $content
        Encoding = $encoding
        NewLine  = $newLine
    }
}

function Write-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][System.Text.Encoding]$Encoding
    )

    Ensure-Directory -Path (Split-Path -Parent $Path)
    [System.IO.File]::WriteAllText($Path, $Content, $Encoding)
}

function Backup-PathIfExists {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$BackupRoot
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Skip "No backup needed: $Path"
        return
    }

    $fullPath = (Resolve-Path -LiteralPath $Path).Path
    $drivePrefix = ""
    if ($fullPath -match '^[A-Za-z]:') {
        $drivePrefix = $fullPath.Substring(0, 1)
        $relativePath = $fullPath.Substring(2).TrimStart('\')
        $backupPath = Join-Path $BackupRoot (Join-Path $drivePrefix $relativePath)
    } else {
        $backupPath = Join-Path $BackupRoot $fullPath.TrimStart('\')
    }

    Ensure-Directory -Path (Split-Path -Parent $backupPath)

    $item = Get-Item -LiteralPath $fullPath
    if ($item.PSIsContainer) {
        Copy-Item -LiteralPath $fullPath -Destination $backupPath -Recurse -Force
    } else {
        Copy-Item -LiteralPath $fullPath -Destination $backupPath -Force
    }

    Write-Ok "Backed up $fullPath"
}

function Remove-MarkedBlock {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$StartMarker,
        [Parameter(Mandatory = $true)][string]$EndMarker
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Skip "Not found: $Path"
        return
    }

    $state = Get-TextFileState -Path $Path
    if ($null -eq $state.Content) {
        Write-Skip "Empty file: $Path"
        return
    }

    $pattern = "(?ms)^[^\S\r\n]*" + [regex]::Escape($StartMarker) + ".*?" + [regex]::Escape($EndMarker) + "[^\r\n]*(\r?\n)?"
    $updated = [regex]::Replace($state.Content, $pattern, "", 1)

    if ($updated -ceq $state.Content) {
        Write-Skip "Block not present in ${Path}: $StartMarker"
        return
    }

    Write-TextFile -Path $Path -Content $updated.TrimStart("`r", "`n") -Encoding $state.Encoding
    Write-Ok "Removed block from ${Path}: $StartMarker"
}

function Remove-AllMarkedBlocks {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object[]]$Markers
    )

    foreach ($marker in $Markers) {
        Remove-MarkedBlock -Path $Path -StartMarker $marker.Start -EndMarker $marker.End
    }
}

function Remove-PathEntry {
    param([Parameter(Mandatory = $true)][string]$Entry)

    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ([string]::IsNullOrWhiteSpace($currentPath)) {
        Write-Skip "User PATH is empty"
        return
    }

    $parts = @($currentPath -split ';' | Where-Object { $_ -and $_.Trim() -ne "" })
    $filtered = @($parts | Where-Object { $_.TrimEnd('\') -ne $Entry.TrimEnd('\') })

    if ($filtered.Count -eq $parts.Count) {
        Write-Skip "User PATH does not contain $Entry"
        return
    }

    [System.Environment]::SetEnvironmentVariable("PATH", ($filtered -join ';'), "User")
    Write-Ok "Removed from user PATH: $Entry"
}

function Remove-FileIfMatchesTemplate {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$TemplatePath
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Skip "Not found: $Path"
        return
    }

    if (-not (Test-Path -LiteralPath $TemplatePath)) {
        Write-Warn "Template not found; skipping comparison: $TemplatePath"
        return
    }

    $fileContent = Get-Content -LiteralPath $Path -Raw
    $templateContent = Get-Content -LiteralPath $TemplatePath -Raw

    if ($fileContent -ceq $templateContent) {
        Remove-Item -LiteralPath $Path -Force
        Write-Ok "Removed template file $Path"
    } else {
        Write-Warn "Left $Path unchanged because it no longer exactly matches the repo template"
    }
}

function Get-GitConfigValue {
    param([Parameter(Mandatory = $true)][string]$Key)
    $value = git config --global --get $Key 2>$null
    if ($LASTEXITCODE -ne 0 -or $null -eq $value) {
        return ""
    }
    return $value.Trim()
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$agentTemplateSource = Join-Path $scriptDir "agent-tools.md"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $env:USERPROFILE ".ai-dev-setup-backups\cleanup-$timestamp"

$ps5Profile = if (Get-Command powershell.exe -ErrorAction SilentlyContinue) {
    (& powershell.exe -NoProfile -Command '$PROFILE').Trim()
} else {
    $null
}

$ps7Profile = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) {
    (& pwsh.exe -NoProfile -Command '$PROFILE').Trim()
} else {
    $null
}

$bashrcPath = Join-Path $env:USERPROFILE ".bashrc"
$claudePath = Join-Path $env:USERPROFILE ".claude\CLAUDE.md"
$agentsPath = Join-Path $env:USERPROFILE "AGENTS.md"
$managedConfigDir = Join-Path $env:USERPROFILE ".ai-dev-setup"
$miseConfigPath = Join-Path $env:APPDATA "mise\config.toml"
$miseFragmentDir = Join-Path $env:APPDATA "mise\conf.d"
$miseFragmentPath = Join-Path $miseFragmentDir "ai-dev-setup-tools.toml"
$miseShimsPath = Join-Path $env:LOCALAPPDATA "mise\shims"
$gitConfigPath = Join-Path $env:USERPROFILE ".gitconfig"

$targets = @(
    $ps5Profile,
    $ps7Profile,
    $bashrcPath,
    $claudePath,
    $agentsPath,
    $gitConfigPath
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

if ($RemoveManagedConfigDir) {
    $targets += $managedConfigDir
}

if ($RemoveMiseFragment) {
    $targets += $miseFragmentPath
}

if ($RemoveMiseConfig) {
    $targets += $miseConfigPath
}

$targets = $targets | Select-Object -Unique

Write-Host "`n─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host " Dev Setup Config Cleanup" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────`n" -ForegroundColor DarkGray
Write-Host " This script will:" -ForegroundColor White
Write-Host "   • back up affected config files" -ForegroundColor White
Write-Host "   • remove legacy dev-tools blocks and current ai-dev-setup include blocks" -ForegroundColor White
Write-Host "   • remove delta git config keys only when they still match the repo defaults" -ForegroundColor White
if ($RemoveManagedConfigDir) {
    Write-Host "   • remove %USERPROFILE%\.ai-dev-setup" -ForegroundColor White
}
if ($RemoveAgentTemplates) {
    Write-Host "   • remove ~/.claude/CLAUDE.md and ~/AGENTS.md only if they still match agent-tools.md exactly" -ForegroundColor White
}
if ($RemoveMiseFragment) {
    Write-Host "   • remove %APPDATA%\\mise\\conf.d\\ai-dev-setup-tools.toml" -ForegroundColor White
}
if ($RemoveMiseConfig) {
    Write-Host "   • remove %APPDATA%\mise\config.toml" -ForegroundColor White
}
if ($RemoveMiseShimsPath) {
    Write-Host "   • remove %LOCALAPPDATA%\mise\shims from the user PATH" -ForegroundColor White
}
Write-Host ""
Write-Host " Installed tools and auth state are left in place." -ForegroundColor DarkGray
Write-Host " Backup location: $backupRoot`n" -ForegroundColor DarkGray

if (-not $Force) {
    $confirmation = Read-Host " Proceed? [Y/n]"
    if ($confirmation -ne "" -and $confirmation -notmatch "^[Yy]") {
        Write-Host "`n Aborted.`n" -ForegroundColor Yellow
        exit 0
    }
}

Write-Step "Backing up affected files"
Ensure-Directory -Path $backupRoot
foreach ($target in $targets) {
    Backup-PathIfExists -Path $target -BackupRoot $backupRoot
}

Write-Step "Removing blocks from PowerShell profiles"
$powershellMarkers = @(
    @{ Start = "# >>> dev-tools: mise >>>"; End = "# <<< dev-tools: mise <<<" }
    @{ Start = "# >>> dev-tools: terminal-icons >>>"; End = "# <<< dev-tools: terminal-icons <<<" }
    @{ Start = "# >>> dev-tools: zoxide-powershell >>>"; End = "# <<< dev-tools: zoxide-powershell <<<" }
    @{ Start = "# >>> ai-dev-setup: include >>>"; End = "# <<< ai-dev-setup: include <<<" }
)

foreach ($profilePath in @($ps5Profile, $ps7Profile) | Where-Object { $_ } | Select-Object -Unique) {
    Remove-AllMarkedBlocks -Path $profilePath -Markers $powershellMarkers
}

Write-Step "Removing blocks from .bashrc"
$bashMarkers = @(
    @{ Start = "# >>> dev-tools: mise-bash >>>"; End = "# <<< dev-tools: mise-bash <<<" }
    @{ Start = "# >>> dev-tools: zoxide-bash >>>"; End = "# <<< dev-tools: zoxide-bash <<<" }
    @{ Start = "# >>> dev-tools: direnv-bash >>>"; End = "# <<< dev-tools: direnv-bash <<<" }
    @{ Start = "# >>> dev-tools: bash-completion >>>"; End = "# <<< dev-tools: bash-completion <<<" }
    @{ Start = "# >>> ai-dev-setup: include >>>"; End = "# <<< ai-dev-setup: include <<<" }
)
Remove-AllMarkedBlocks -Path $bashrcPath -Markers $bashMarkers

Write-Step "Removing legacy injected agent blocks"
$agentMarkers = @(
    @{ Start = "<!-- >>> dev-tools: agent-tools >>> -->"; End = "<!-- <<< dev-tools: agent-tools <<< -->" }
    @{ Start = "<!-- >>> ai-dev-setup: agent-tools >>> -->"; End = "<!-- <<< ai-dev-setup: agent-tools <<< -->" }
)
Remove-AllMarkedBlocks -Path $claudePath -Markers $agentMarkers
Remove-AllMarkedBlocks -Path $agentsPath -Markers $agentMarkers

if ($RemoveAgentTemplates) {
    Write-Step "Removing agent template files when they still match the repo template"
    Remove-FileIfMatchesTemplate -Path $claudePath -TemplatePath $agentTemplateSource
    Remove-FileIfMatchesTemplate -Path $agentsPath -TemplatePath $agentTemplateSource
}

if ($RemoveManagedConfigDir) {
    Write-Step "Removing managed config directory"
    if (Test-Path -LiteralPath $managedConfigDir) {
        Remove-Item -LiteralPath $managedConfigDir -Recurse -Force
        Write-Ok "Removed $managedConfigDir"
    } else {
        Write-Skip "Not found: $managedConfigDir"
    }
}

if ($RemoveMiseFragment) {
    Write-Step "Removing repo-owned global mise fragment"
    if (Test-Path -LiteralPath $miseFragmentPath) {
        Remove-Item -LiteralPath $miseFragmentPath -Force
        Write-Ok "Removed $miseFragmentPath"
    } else {
        Write-Skip "Not found: $miseFragmentPath"
    }
}

if ($RemoveMiseConfig) {
    Write-Step "Removing global mise config"
    if (Test-Path -LiteralPath $miseConfigPath) {
        Remove-Item -LiteralPath $miseConfigPath -Force
        Write-Ok "Removed $miseConfigPath"
    } else {
        Write-Skip "Not found: $miseConfigPath"
    }
}

if ($RemoveMiseShimsPath) {
    Write-Step "Removing mise shims from user PATH"
    Remove-PathEntry -Entry $miseShimsPath
}

Write-Step "Removing delta git config keys"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Skip "git not found — skipping git config cleanup"
} else {
    $gitDefaults = @(
        [pscustomobject]@{ Key = "core.pager";             Value = "delta" }
        [pscustomobject]@{ Key = "interactive.diffFilter"; Value = "delta --color-only" }
        [pscustomobject]@{ Key = "delta.navigate";         Value = "true" }
        [pscustomobject]@{ Key = "delta.side-by-side";     Value = "true" }
        [pscustomobject]@{ Key = "merge.conflictstyle";    Value = "diff3" }
        [pscustomobject]@{ Key = "diff.colorMoved";        Value = "default" }
    )

    foreach ($setting in $gitDefaults) {
        $currentValue = Get-GitConfigValue -Key $setting.Key
        if ($currentValue -eq $setting.Value) {
            git config --global --unset $setting.Key 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "unset git $($setting.Key)"
            } else {
                Write-Warn "failed to unset git $($setting.Key)"
            }
        } elseif ([string]::IsNullOrWhiteSpace($currentValue)) {
            Write-Skip "git $($setting.Key) not set"
        } else {
            Write-Skip "git $($setting.Key) has a different value; left unchanged"
        }
    }
}

Write-Host "`n─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host " Cleanup complete." -ForegroundColor Cyan
Write-Host " Open a new terminal to verify the cleaned config state." -ForegroundColor Yellow
Write-Host " Backups were written to: $backupRoot" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────`n" -ForegroundColor DarkGray
