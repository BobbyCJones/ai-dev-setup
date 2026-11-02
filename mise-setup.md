# Machine Setup

Installs universal CLI tools via [mise](https://mise.jdx.dev), configures git defaults conservatively, installs a repo-owned global mise fragment, installs repo-managed shell snippets, and optionally creates starter agent config files. Run once per machine.

## Overview

[mise](https://mise.jdx.dev) is a polyglot tool version manager. This repo uses a local [mise.toml](mise.toml) as the canonical tool manifest. The setup script installs a repo-owned fragment at `%APPDATA%\mise\conf.d\ai-dev-setup-tools.toml`, which makes those tools active everywhere without taking ownership of your main global `%APPDATA%\mise\config.toml`.

Repo-managed sources:

- mise fragment source: [mise.toml](mise.toml), installed unchanged
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

The steps it performs are listed in [README.md](README.md#global-machine-setup). It uses `agent-tools-claude.md` for Claude Code and `agent-tools.md` for Codex/generic CLI agents.

### 3. Open a new terminal

All shell changes take effect in new terminal windows.

### 4. Authenticate GitHub CLI

```bash
gh auth login
```

### 5. Configure MCP servers in Claude Code

The Azure DevOps MCP is required for ADO work items, PRs, pipelines, and wikis (`/ado-ticket` depends on it):

```bash
claude mcp add azure-devops -- npx -y @azure-devops/mcp <your-org>
```

The server signs you in with a Microsoft account on first use. Verify with `claude mcp list`.

The GitHub MCP is optional. When configured, agents use it for interactive GitHub browsing. Scripts and slash commands use `gh`.

### 6. Verify

```bash
mise list
rg --version
delta --version
gh auth status
```

### 7. Inspect the managed files

```powershell
Get-ChildItem $HOME\.ai-dev-setup -Recurse
Get-ChildItem $env:APPDATA\mise\conf.d
```

## Reference

- Ownership boundaries: [README.md](README.md#ownership-boundaries)
- Installed tools: [README.md](README.md#installed-tools)
- Per-project setup: [project-setup.md](project-setup.md)
