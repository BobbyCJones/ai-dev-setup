# Machine Setup

Installs universal CLI tools via [mise](https://mise.jdx.dev), configures git defaults conservatively, installs a repo-owned global mise fragment, installs repo-managed shell snippets, and optionally creates starter agent config files. Run once per machine.

## Overview

[mise](https://mise.jdx.dev) is a polyglot tool version manager. This repo uses a local [mise.toml](mise.toml) as the canonical tool manifest. The setup script installs a repo-owned fragment at `%APPDATA%\mise\conf.d\ai-dev-setup-tools.toml`, which makes those tools active everywhere without taking ownership of your main global `%APPDATA%\mise\config.toml`.

Repo-managed sources:

- mise fragment source: [managed-config/mise/ai-dev-setup-tools.toml](managed-config/mise/ai-dev-setup-tools.toml)
- PowerShell snippet source: [managed-config/powershell/dev-tools-profile.ps1](managed-config/powershell/dev-tools-profile.ps1)
- Bash snippet source: [managed-config/bash/dev-tools.bash](managed-config/bash/dev-tools.bash)

The installer copies those files to `~/.ai-dev-setup/` and adds a single include block to each shell profile. That keeps the repo-owned behavior isolated from the rest of your personal config.

## Agent-Assisted Setup

```bash
# Claude Code
claude "Read mise-setup.md and set up my dev environment following the manual setup instructions"

# Codex
codex "Read mise-setup.md and set up my dev environment following the manual setup instructions"
```

For Cursor: open this folder in Cursor, launch Composer (`Ctrl+I`), and send the same prompt.

## Manual Setup

### 1. Install mise

```powershell
winget install jdx.mise --scope user
```

Close and reopen your terminal after installing.

### 2. Run the setup script

From this directory:

```powershell
.\install-dev-tools.ps1
```

Optional flags:

```powershell
.\install-dev-tools.ps1 -Yes
.\install-dev-tools.ps1 -Yes -InstallAgentTemplates
```

Or double-click `install-dev-tools.bat`.

The script handles everything else:

- Installs a repo-owned global mise fragment under `%APPDATA%\mise\conf.d`
- Runs `mise install` from this repo to install the toolset declared in [mise.toml](mise.toml)
- Adds `%LOCALAPPDATA%\mise\shims` to your user `PATH` if needed
- Configures git to use delta defaults only when those keys are currently unset
- Installs `PSReadLine` and `Terminal-Icons` in `CurrentUser` scope
- Copies repo-managed shell snippets to `~/.ai-dev-setup/`
- Adds one include block to PowerShell profiles and `~/.bashrc`
- Optionally creates or updates repo-managed blocks in `~/.claude/CLAUDE.md` and `~/AGENTS.md`
- Uses `agent-tools-claude.md` for Claude Code and `agent-tools.md` for Codex/generic CLI agents

### 3. Open a new terminal

All shell changes take effect in new terminal windows.

### 4. Authenticate GitHub CLI

```bash
gh auth login
```

### 5. Verify

```bash
mise list
rg --version
delta --version
gh auth status
```

### 6. Inspect the managed files

```powershell
Get-ChildItem $HOME\.ai-dev-setup -Recurse
Get-ChildItem $env:APPDATA\mise\conf.d
```

## Ownership Boundaries

This repo owns:

- [mise.toml](mise.toml) as the tool manifest
- The files in [managed-config/](managed-config)
- The repo-owned global mise fragment under `%APPDATA%\mise\conf.d`
- The copied managed shell snippets under `~/.ai-dev-setup/`
- The include blocks it adds to PowerShell profiles and `~/.bashrc`

This repo does not overwrite:

- `%APPDATA%\mise\config.toml`
- User content in `~/.claude/CLAUDE.md`; with `-InstallAgentTemplates`, only the repo-managed block is created or updated
- User content in `~/AGENTS.md`; with `-InstallAgentTemplates`, only the repo-managed block is created or updated
- Existing git config values that differ from the repo's suggested defaults

## Tool Reference

Tools ordered by impact for agent-assisted development.

### Tier 1 — Essential

These tools are directly used by agents or unlock core capabilities.

#### `ripgrep` (rg)

Fast code search across a codebase. Claude Code uses ripgrep internally for all file content searches. Significantly faster than `grep` and respects `.gitignore` automatically.

#### `fd`

Fast, user-friendly alternative to `find`. Agents use it to discover files by name or pattern. Simpler syntax, respects `.gitignore`, handles Unicode paths.

#### `jq`

JSON processor for the command line. Agents use this constantly — parsing API responses, reading `package.json`, manipulating config files. Without it, agents resort to fragile text parsing.

#### `gh` (GitHub CLI)

GitHub operations from the terminal. Agents use this to create PRs, comment on issues, check CI status, and manage branches without leaving the terminal.

### Tier 2 — High Value

These tools improve how agents and developers work together.

#### `bat`

Syntax-highlighted `cat` with line numbers and paging. Makes file output readable when reviewing agent changes.

#### `delta`

Syntax-highlighted git diffs with side-by-side view. Makes reviewing agent commits and diffs significantly easier.

#### `fzf`

Interactive fuzzy finder. Lets agents build selection menus that hand off a single decision to the developer. Also enhances shell history search (`Ctrl+R`).

#### `yq`

Like `jq` but for YAML, TOML, and XML. Agents use it to edit CI pipelines, Kubernetes manifests, and Docker Compose files without brittle line-based editing.

#### `sqlcmd`

Microsoft's SQL Server CLI. Run queries against SQL Server or Azure SQL from the terminal. Agents use it to inspect schemas, run migrations, and validate data without needing SSMS or a GUI.

#### `az` (Azure CLI)

Microsoft's Azure CLI. Provision and manage Azure resources, query resource state, and interact with Azure services from the terminal. Agents use it instead of raw REST calls to the Azure API.

The `azure-devops` extension is installed automatically, enabling `az devops`, `az pipelines`, `az repos`, and `az boards` commands for working with Azure DevOps organizations, projects, pipelines, and repositories.

### Tier 3 — Quality of Life

#### `zoxide`

A smarter `cd` that learns your most-visited directories. Jump anywhere with a partial name (`z scratch`, `z myproject`).

#### `eza`

A modern replacement for `ls` with color, icons, and git status per file. Helps orient in a directory after agent changes.

#### `tldr`

Simplified man pages with practical examples. Quickly look up any CLI tool an agent suggests (`tldr delta`, `tldr jq`).

#### `direnv`

Auto-loads environment variables when entering a directory. Keeps project-specific API keys and secrets isolated. See [project-setup.md](project-setup.md) for usage.
