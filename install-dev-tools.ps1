# install-dev-tools.ps1
# Configures a Windows developer machine for agent-assisted development.
# Installs mise, installs tools from the repo's manifest, configures git,
# installs repo-managed shell snippets, and optionally creates agent templates.
# Safe to run multiple times -- skips or preserves user-owned config when possible.
#
# Usage:
#   .\install-dev-tools.ps1
#   .\install-dev-tools.ps1 -Yes
#   .\install-dev-tools.ps1 -Yes -InstallAgentTemplates
#
# Requirements:
#   - Windows 10/11 with winget (App Installer)
#   - PowerShell 5.1 or 7+
#   - Internet access

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Yes,
    [switch]$InstallAgentTemplates
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$script:HadWarnings = $false
$script:HadFailures = $false

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
    $script:HadWarnings = $true
    Write-Host "   [??] $Message" -ForegroundColor Yellow
}

function Write-Fail($Message) {
    $script:HadFailures = $true
    Write-Host "   [!!] $Message" -ForegroundColor Red
}

function Test-CommandAvailable {
    param([Parameter(Mandatory = $true)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Ensure-ParentDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)
    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
}

function Ensure-FileExists {
    param([Parameter(Mandatory = $true)][string]$Path)
    Ensure-ParentDirectory -Path $Path
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType File -Force -Path $Path | Out-Null
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

    Ensure-ParentDirectory -Path $Path
    [System.IO.File]::WriteAllText($Path, $Content, $Encoding)
}

function Add-NamedBlockIfMissing {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][string]$Marker,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $state = Get-TextFileState -Path $File
    if ($state.Content -match [regex]::Escape($Marker)) {
        return $false
    }

    $normalizedContent = ($Content -replace "`r`n", "`n") -replace "`r", "`n"
    if ($state.NewLine -ne "`n") {
        $normalizedContent = $normalizedContent -replace "`n", $state.NewLine
    }

    $prefix = if ([string]::IsNullOrEmpty($state.Content)) { "" } else { $state.NewLine }
    Write-TextFile -Path $File -Content ($state.Content + $prefix + $normalizedContent) -Encoding $state.Encoding
    return $true
}

function Set-NamedBlock {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][string]$StartMarker,
        [Parameter(Mandatory = $true)][string]$EndMarker,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $state = Get-TextFileState -Path $File
    $normalizedContent = ($Content -replace "`r`n", "`n") -replace "`r", "`n"
    if ($state.NewLine -ne "`n") {
        $normalizedContent = $normalizedContent -replace "`n", $state.NewLine
    }

    $blockPattern = "(?ms)^[^\S\r\n]*" + [regex]::Escape($StartMarker) + ".*?" + [regex]::Escape($EndMarker) + "[^\r\n]*(\r?\n)?"
    $existingBlock = [regex]::Match($state.Content, $blockPattern)

    if ($existingBlock.Success) {
        if ($existingBlock.Value.Trim() -eq $normalizedContent.Trim()) {
            return "unchanged"
        }

        $updated = $state.Content.Substring(0, $existingBlock.Index) + $normalizedContent + $state.Content.Substring($existingBlock.Index + $existingBlock.Length)
        Write-TextFile -Path $File -Content $updated -Encoding $state.Encoding
        return "updated"
    }

    $prefix = if ([string]::IsNullOrEmpty($state.Content)) { "" } else { $state.NewLine }
    Write-TextFile -Path $File -Content ($state.Content + $prefix + $normalizedContent) -Encoding $state.Encoding
    return "inserted"
}

function Install-ManagedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Fail "Managed source file not found: $Source"
        return
    }

    Ensure-ParentDirectory -Path $Destination

    if (Test-Path -LiteralPath $Destination) {
        $sourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
        $destHash   = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
        if ($sourceHash -eq $destHash) {
            Write-Skip "managed file already current: $Destination"
            return
        }
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Ok "managed file updated -> $Destination"
    } else {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Ok "managed file installed -> $Destination"
    }
}

function Get-GitConfigValue {
    param([Parameter(Mandatory = $true)][string]$Key)
    $value = git config --global $Key 2>$null
    if ($LASTEXITCODE -ne 0 -or $null -eq $value) {
        return ""
    }
    return $value.Trim()
}

function Set-GitConfigIfUnset {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $currentValue = Get-GitConfigValue -Key $Key
    if ($currentValue -eq $Value) {
        Write-Skip "git $Key already set"
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($currentValue)) {
        Write-Warn "git $Key already has a different value; leaving it unchanged"
        Write-Host "       Current: $currentValue" -ForegroundColor DarkGray
        Write-Host "       Wanted : $Value" -ForegroundColor DarkGray
        return
    }

    git config --global $Key "$Value"
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "git $Key = $Value"
    } else {
        Write-Fail "git $Key update failed"
    }
}

function Test-ModuleInstallPrerequisites {
    try {
        Import-Module PowerShellGet -ErrorAction Stop | Out-Null
    } catch {
        Write-Warn "PowerShellGet could not be loaded in this PowerShell session"
        Write-Host "       $($_.Exception.Message)" -ForegroundColor DarkGray
        return $false
    }

    if (-not (Get-Command Install-Module -ErrorAction SilentlyContinue)) {
        Write-Warn "Install-Module is not available in this PowerShell session"
        return $false
    }

    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
        $errors = @()
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force -ErrorAction SilentlyContinue -ErrorVariable +errors | Out-Null
        if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
            Write-Fail "NuGet package provider is required before installing PowerShell modules"
            foreach ($errorRecord in $errors) {
                Write-Host "       $($errorRecord.Exception.Message)" -ForegroundColor DarkGray
            }
            Write-Host "       Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force" -ForegroundColor DarkGray
            return $false
        }
        Write-Ok "NuGet package provider"
    } else {
        Write-Skip "NuGet package provider already installed"
    }

    $gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if ($null -eq $gallery) {
        Write-Fail "PSGallery repository is not registered"
        Write-Host "       Register-PSRepository -Default" -ForegroundColor DarkGray
        return $false
    }

    return $true
}

function Get-CurrentUserExecutionPolicy {
    try {
        Import-Module Microsoft.PowerShell.Security -ErrorAction Stop | Out-Null
    } catch {
        Write-Warn "Execution policy could not be inspected in this PowerShell session"
        Write-Host "       $($_.Exception.Message)" -ForegroundColor DarkGray
        return $null
    }

    try {
        return Get-ExecutionPolicy -Scope CurrentUser -ErrorAction Stop
    } catch {
        Write-Warn "Execution policy lookup failed in this PowerShell session"
        Write-Host "       $($_.Exception.Message)" -ForegroundColor DarkGray
        return $null
    }
}

function Install-RequiredModule {
    param([Parameter(Mandatory = $true)][string]$Name)

    if (Get-Module -ListAvailable -Name $Name) {
        Write-Skip "$Name already installed"
        return
    }

    $errors = @()
    Install-Module $Name -Scope CurrentUser -Force -ErrorAction SilentlyContinue -ErrorVariable +errors

    if (Get-Module -ListAvailable -Name $Name) {
        Write-Ok $Name
        return
    }

    Write-Fail "$Name install failed"
    foreach ($errorRecord in $errors) {
        Write-Host "       $($errorRecord.Exception.Message)" -ForegroundColor DarkGray
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$managedRoot = Join-Path $env:USERPROFILE ".ai-dev-setup"
$repoManagedConfigDir = Join-Path $scriptDir "managed-config"
$miseManagedFragmentName = "ai-dev-setup-tools.toml"

$managedPowerShellSource = Join-Path $repoManagedConfigDir "powershell\dev-tools-profile.ps1"
$managedBashSource = Join-Path $repoManagedConfigDir "bash\dev-tools.bash"
$managedMiseFragmentSource = Join-Path $repoManagedConfigDir "mise\$miseManagedFragmentName"
$managedPowerShellTarget = Join-Path $managedRoot "powershell\dev-tools-profile.ps1"
$managedBashTarget = Join-Path $managedRoot "bash\dev-tools.bash"
$agentTemplateSource = Join-Path $scriptDir "agent-tools.md"

function Get-MiseConfigDir {
    return Join-Path $env:APPDATA "mise"
}

Write-Host "`n---------------------------------------------" -ForegroundColor DarkGray
Write-Host " AI Developer Environment Setup" -ForegroundColor Cyan
Write-Host "---------------------------------------------`n" -ForegroundColor DarkGray
Write-Host " This script will make the following changes to your machine:`n" -ForegroundColor White
Write-Host " INSTALL (via winget, if not already present)" -ForegroundColor Yellow
Write-Host "   * mise  -- tool version manager that installs everything below" -ForegroundColor White
Write-Host ""
Write-Host " INSTALL TOOLS (from this repo's mise.toml)" -ForegroundColor Yellow
Write-Host "   * ripgrep, fd       -- fast file and content search" -ForegroundColor White
Write-Host "   * jq, yq, mlr       -- JSON, YAML, and CSV processors" -ForegroundColor White
Write-Host "   * gh                -- GitHub CLI" -ForegroundColor White
Write-Host "   * sqlcmd            -- SQL Server / Azure SQL query runner" -ForegroundColor White
Write-Host "   * az                -- Azure CLI (+ azure-devops extension)" -ForegroundColor White
Write-Host "   * sg (ast-grep)     -- structural code search and replace" -ForegroundColor White
Write-Host "   * shellcheck, shfmt -- shell script linting and formatting" -ForegroundColor White
Write-Host "   * bat               -- syntax-highlighted file viewer (cat replacement)" -ForegroundColor White
Write-Host "   * delta             -- syntax-highlighted diff viewer" -ForegroundColor White
Write-Host "   * fzf               -- fuzzy finder" -ForegroundColor White
Write-Host "   * zoxide            -- smarter cd command" -ForegroundColor White
Write-Host "   * eza               -- modern file listing (ls replacement)" -ForegroundColor White
Write-Host "   * tlrc              -- community-maintained command cheat sheets" -ForegroundColor White
Write-Host "   * direnv            -- per-directory environment variables" -ForegroundColor White
Write-Host ""
Write-Host " CONFIGURE" -ForegroundColor Yellow
Write-Host "   * Global mise      -> install repo-owned fragment in %APPDATA%\\mise\\conf.d" -ForegroundColor White
Write-Host "   * User PATH         -- add mise shims so tools work in all apps" -ForegroundColor White
Write-Host "   * Git global config -- set delta defaults only when unset" -ForegroundColor White
Write-Host "   * Managed snippets  -> %USERPROFILE%\\.ai-dev-setup" -ForegroundColor White
Write-Host "   * PowerShell / bash -- add one include block that sources those snippets" -ForegroundColor White
if ($InstallAgentTemplates) {
    Write-Host "   * Agent templates   -- create or update a repo-managed block in ~/.claude/CLAUDE.md and ~/AGENTS.md" -ForegroundColor White
} else {
    Write-Host "   * Agent templates   -- no global agent files will be modified" -ForegroundColor White
}
Write-Host ""
Write-Host " INSTALL PowerShell modules (CurrentUser scope)" -ForegroundColor Yellow
Write-Host "   * PSReadLine        -- improved PowerShell editing experience" -ForegroundColor White
Write-Host "   * Terminal-Icons    -- file type icons in terminal listings" -ForegroundColor White
Write-Host ""
Write-Host " This script does not overwrite %APPDATA%\\mise\\config.toml; it manages a separate fragment file.`n" -ForegroundColor DarkGray
Write-Host "---------------------------------------------`n" -ForegroundColor DarkGray

if (-not $Yes) {
    $confirmation = Read-Host " Proceed? [Y/n]"
    if ($confirmation -ne "" -and $confirmation -notmatch "^[Yy]") {
        Write-Host "`n Aborted.`n" -ForegroundColor Yellow
        exit 0
    }
}

if (Test-CommandAvailable -Name "mise") {
    mise trust (Join-Path $scriptDir "mise.toml") 2>&1 | Out-Null
}

Write-Step "Installing mise"

if (-not (Test-CommandAvailable -Name "winget")) {
    Write-Fail "winget not found. Install App Installer from Microsoft and re-run this script."
} elseif (Test-CommandAvailable -Name "mise") {
    Write-Skip "mise already installed"
} else {
    $output = winget install jdx.mise --scope user --accept-source-agreements --accept-package-agreements --disable-interactivity 2>&1
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($LASTEXITCODE -eq 0 -or (Test-CommandAvailable -Name "mise")) {
        Write-Ok "mise installed"
    } else {
        Write-Fail "mise install failed (exit code $LASTEXITCODE)"
        $output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
            Write-Host "       $_" -ForegroundColor DarkGray
        }
    }
}

Write-Step "Installing tools from this repo's mise.toml"

if (-not (Test-CommandAvailable -Name "mise")) {
    Write-Skip "mise not found -- skipping tool installation"
} else {
    $managedMiseFragmentTarget = Join-Path (Get-MiseConfigDir) "conf.d\$miseManagedFragmentName"
    Install-ManagedFile -Source $managedMiseFragmentSource -Destination $managedMiseFragmentTarget
    mise trust $managedMiseFragmentTarget 2>&1 | Out-Null

    Push-Location $scriptDir
    try {
        mise trust (Join-Path $scriptDir "mise.toml") 2>&1 | Out-Null
        $output = mise install 2>&1
    } finally {
        Pop-Location
    }
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "mise tools installed from repo manifest"
    } else {
        Write-Fail "mise install failed"
        $output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
            Write-Host "       $_" -ForegroundColor DarkGray
        }
    }

    $shimsDir = Join-Path $env:LOCALAPPDATA "mise\shims"
    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $pathParts = @($currentPath -split ";" | Where-Object { $_ -and $_.Trim() -ne "" })
    if ($pathParts -contains $shimsDir) {
        Write-Skip "mise shims already on User PATH"
    } else {
        [System.Environment]::SetEnvironmentVariable("PATH", "$shimsDir;$currentPath", "User")
        Write-Ok "mise shims added to User PATH ($shimsDir)"
    }

    # Also prepend shims to the current process PATH so subsequent steps can find tools
    # that were just installed by mise without requiring a new terminal session.
    if ($env:PATH -notlike "*$shimsDir*") {
        $env:PATH = "$shimsDir;$env:PATH"
    }
}

Write-Step "Installing Azure CLI extensions"

if (-not (Test-CommandAvailable -Name "az")) {
    Write-Skip "az not found -- skipping extension installation"
} else {
    $azExtensions = az extension list --query "[].name" -o tsv 2>$null
    if ($azExtensions -match "azure-devops") {
        Write-Skip "azure-devops extension already installed"
    } else {
        $output = az extension add --name azure-devops --only-show-errors 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "azure-devops extension installed"
        } else {
            Write-Fail "azure-devops extension install failed"
            $output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
                Write-Host "       $_" -ForegroundColor DarkGray
            }
        }
    }
}

Write-Step "Configuring git to use delta for diffs"

$hasGit = Test-CommandAvailable -Name "git"
$hasDelta = Test-CommandAvailable -Name "delta"

if (-not $hasGit) {
    Write-Skip "git not found in PATH -- skipping git config"
} elseif (-not $hasDelta) {
    Write-Skip "delta not found in PATH -- skipping git config"
} else {
    $gitSettings = @(
        [pscustomobject]@{ Key = "core.pager";             Value = "delta" }
        [pscustomobject]@{ Key = "interactive.diffFilter"; Value = "delta --color-only" }
        [pscustomobject]@{ Key = "delta.navigate";         Value = "true" }
        [pscustomobject]@{ Key = "delta.side-by-side";     Value = "true" }
        [pscustomobject]@{ Key = "merge.conflictstyle";    Value = "diff3" }
        [pscustomobject]@{ Key = "diff.colorMoved";        Value = "default" }
    )

    foreach ($setting in $gitSettings) {
        Set-GitConfigIfUnset -Key $setting.Key -Value $setting.Value
    }
}

Write-Step "Installing PowerShell modules"

if (Test-ModuleInstallPrerequisites) {
    foreach ($moduleName in @("PSReadLine", "Terminal-Icons")) {
        Install-RequiredModule -Name $moduleName
    }
} else {
    Write-Warn "Skipping PowerShell module installation until prerequisites are available"
}

Write-Step "Installing managed shell snippets"
Install-ManagedFile -Source $managedPowerShellSource -Destination $managedPowerShellTarget
Install-ManagedFile -Source $managedBashSource -Destination $managedBashTarget

Write-Step "Configuring PowerShell profiles"

$policy = Get-CurrentUserExecutionPolicy
if ($null -eq $policy) {
    Write-Skip "ExecutionPolicy check skipped for this PowerShell session"
} elseif ($policy -eq "Restricted" -or $policy -eq "Undefined") {
    Write-Warn "CurrentUser execution policy is '$policy' -- profile scripts will not load automatically."
    Write-Host "       Run this once in a PowerShell terminal if you want profile scripts enabled:" -ForegroundColor DarkGray
    Write-Host "       Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor DarkGray
} else {
    Write-Skip "ExecutionPolicy already allows profile scripts ($policy)"
}

$psIncludeBlock = @"
# >>> ai-dev-setup: include >>>
`$aiDevSetupProfile = Join-Path `$HOME ".ai-dev-setup\powershell\dev-tools-profile.ps1"
if (Test-Path -LiteralPath `$aiDevSetupProfile) {
    . `$aiDevSetupProfile
}
# <<< ai-dev-setup: include <<<
"@

$psHosts = @(
    [pscustomobject]@{ Name = "PowerShell 5"; Exe = "powershell.exe" }
    [pscustomobject]@{ Name = "PowerShell 7"; Exe = "pwsh.exe" }
)

foreach ($psHost in $psHosts) {
    if (-not (Test-CommandAvailable -Name $psHost.Exe)) {
        Write-Skip "$($psHost.Name) not found"
        continue
    }

    $profilePath = & $psHost.Exe -NoProfile -Command '$PROFILE'
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($profilePath)) {
        Write-Fail "$($psHost.Name) profile path lookup failed"
        continue
    }

    $profilePath = $profilePath.Trim()
    if (Add-NamedBlockIfMissing -File $profilePath -Marker ">>> ai-dev-setup: include >>>" -Content $psIncludeBlock) {
        Write-Ok "$($psHost.Name) include block added"
    } else {
        Write-Skip "$($psHost.Name) include block already configured"
    }
}

Write-Step "Configuring bash (.bashrc)"

$bashrc = Join-Path $env:USERPROFILE ".bashrc"
$bashIncludeBlock = @"
# >>> ai-dev-setup: include >>>
if [ -f "`$HOME/.ai-dev-setup/bash/dev-tools.bash" ]; then
    . "`$HOME/.ai-dev-setup/bash/dev-tools.bash"
fi
# <<< ai-dev-setup: include <<<
"@

if (Add-NamedBlockIfMissing -File $bashrc -Marker ">>> ai-dev-setup: include >>>" -Content $bashIncludeBlock) {
    Write-Ok "bash include block added"
} else {
    Write-Skip "bash include block already configured"
}

Write-Step "Handling agent templates"

if (-not (Test-Path -LiteralPath $agentTemplateSource)) {
    Write-Fail "agent-tools.md not found at $agentTemplateSource"
} elseif (-not $InstallAgentTemplates) {
    Write-Skip "agent templates not requested"
    Write-Host "       Use agent-tools.md as a manual starting point for ~/.claude/CLAUDE.md or ~/AGENTS.md" -ForegroundColor DarkGray
} else {
    $agentTemplateContent = Get-Content -LiteralPath $agentTemplateSource -Raw
    $agentTargets = @(
        [pscustomobject]@{ Path = (Join-Path $env:USERPROFILE ".claude\CLAUDE.md"); Label = "Claude template" }
        [pscustomobject]@{ Path = (Join-Path $env:USERPROFILE "AGENTS.md"); Label = "Codex template" }
    )

    foreach ($target in $agentTargets) {
        $managedBlock = @"
<!-- >>> ai-dev-setup: agent-tools >>> -->
$agentTemplateContent
<!-- <<< ai-dev-setup: agent-tools <<< -->
"@

        $result = Set-NamedBlock -File $target.Path -StartMarker "<!-- >>> ai-dev-setup: agent-tools >>> -->" -EndMarker "<!-- <<< ai-dev-setup: agent-tools <<< -->" -Content $managedBlock
        switch ($result) {
            "inserted" { Write-Ok "$($target.Label) managed block added to $($target.Path)" }
            "updated"  { Write-Ok "$($target.Label) managed block updated in $($target.Path)" }
            default    { Write-Skip "$($target.Label) managed block already current" }
        }
    }

    Write-Warn "Cursor: open Settings -> Rules for AI and copy the contents of agent-tools.md if desired"
}

Write-Host "`n---------------------------------------------" -ForegroundColor DarkGray
if ($script:HadFailures) {
    Write-Host " Setup completed with failures." -ForegroundColor Red
} elseif ($script:HadWarnings) {
    Write-Host " Setup completed with warnings." -ForegroundColor Yellow
} else {
    Write-Host " Setup complete." -ForegroundColor Cyan
}
Write-Host " Open a new terminal window for all changes to take effect." -ForegroundColor Yellow
Write-Host " Run 'gh auth login' if you haven't authenticated with GitHub." -ForegroundColor Yellow
Write-Host " Run 'az login' if you haven't authenticated with Azure." -ForegroundColor Yellow
Write-Host " Managed shell files live under %USERPROFILE%\\.ai-dev-setup." -ForegroundColor Yellow
Write-Host "---------------------------------------------`n" -ForegroundColor DarkGray
