# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Cursor) working in this repository.

## What This Repo Is

A Windows developer-environment toolkit. It installs a CLI toolchain with mise, wires shell activation, and deploys global agent instructions. It contains scripts and docs only: no build, test, or lint commands.

User-facing setup lives in [README.md](README.md). This file covers maintenance.

## Layout

| Path | Purpose |
|---|---|
| `README.md` | Setup entry point, tool list, ownership boundaries |
| `mise-setup.md` | Step-by-step setup and verification |
| `project-setup.md` | Per-project `mise.toml`, `.envrc`, and agent file guidance |
| `install-dev-tools.ps1` | Idempotent installer (`-Yes`, `-InstallAgentTemplates`) |
| `install-dev-tools.bat` | Double-click wrapper; always passes `-InstallAgentTemplates` |
| `mise.toml` | Tool manifest; also installed as `%APPDATA%\mise\conf.d\ai-dev-setup-tools.toml` |
| `managed-config/powershell/`, `managed-config/bash/` | Shell snippets copied to `~/.ai-dev-setup/` |
| `managed-config/claude/commands/` | Slash commands copied to `~/.claude/commands/` |
| `managed-config/claude/settings-permissions.json` | Allow and deny rules merged into `~/.claude/settings.json` |
| `agent-tools-claude.md` | Source for the managed block in `~/.claude/CLAUDE.md` |
| `agent-tools.md` | Source for the managed block in `~/.codex/AGENTS.md` |
| `agent-runtime-test.md` | Prompt an agent runs to verify tools and instruction files |

## Installer Flow

1. Install mise via winget if missing.
2. Copy `mise.toml` to `conf.d` as the global fragment, run `mise install` here, add mise shims to the User `PATH`.
3. Set delta-related git config keys only when unset.
4. Install `PSReadLine` and `Terminal-Icons`.
5. Copy shell snippets and add one include block to each PowerShell profile and `~/.bashrc`.
6. With `-InstallAgentTemplates`: update the managed blocks in the two global agent files and merge permission rules.
7. Copy `managed-config/claude/commands/*.md` to `~/.claude/commands/`.

## Maintenance Rules

- The two `agent-tools*.md` templates share most content. Change shared sections in both; keep Claude-only (MCP, `/ado-ticket`, `/fork-pr`) and Codex-only (inline fork-PR steps) sections in their own file.
- Template changes reach machines only after re-running the installer with `-InstallAgentTemplates`.
- The installer replaces content between its marker comments. Never document edits to text inside a managed block as durable.
- New tools go in `mise.toml`, the installer banner, the README tool table, and an allow rule in `settings-permissions.json` when agents should run them unprompted.
- New files under `managed-config/claude/commands/` deploy automatically.
- Scripts run in Git Bash and PowerShell. WSL is not assumed.
- The bash snippet skips `mise activate` under MSYS because it corrupts `PATH`; shims provide version switching there.
- Run `shellcheck` and `shfmt -w` on any shell script you change.

## Verification

No automated tests exist. After installer or template changes:

1. Run `.\install-dev-tools.ps1 -Yes -InstallAgentTemplates` twice. On the second run, every managed file and block must report `[--]`.
2. Open a new shell and run `mise list`.
3. Run the check in [agent-runtime-test.md](agent-runtime-test.md) from outside this repo.

## Writing Standards

Defined in the agent templates under "Writing standards". Apply them to every doc here.
