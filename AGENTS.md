# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Codex, Cursor, etc.) when working with code in this repository.

## What This Repo Is

A developer environment setup toolkit for Windows machines. It standardizes a CLI toolchain and shell activation for agent-assisted development. There are no build steps, tests, or lint commands — this repo contains scripts and documentation, not an application.

## Setup

Run the machine setup once per machine:

```bash
# Agent-assisted (recommended) — prompt any agent:
# "Read the README.md and set up my dev environment following the instructions"

# Manual
.\install-dev-tools.ps1
```

All setup steps are idempotent — safe to re-run.

## Architecture

| File/Dir | Purpose |
|---|---|
| `README.md` | Top-level setup entry point and ownership boundaries |
| `mise-setup.md` | Primary setup guide and verification steps |
| `install-dev-tools.ps1` | PowerShell automation of the machine setup |
| `mise.toml` | Canonical tool manifest used by `mise install` from this repo |
| `managed-config/` | Repo-owned mise and shell snippets installed under user config directories |
| `project-setup.md` | Template for per-project `mise.toml`, `.envrc`, and agent instructions |
| `agent-tools-claude.md` | Claude Code-specific global template content for `CLAUDE.md` |
| `agent-tools.md` | Codex/generic CLI global template content for `AGENTS.md` |
| `cleanup-dev-tools-config.ps1` | Temporary debug helper for resetting machine config during installer iteration |

The flow: `install-dev-tools.ps1` installs mise if needed → installs a repo-owned global mise fragment under `%APPDATA%\mise\conf.d` → runs `mise install` from this repo → configures git defaults conservatively → copies managed shell snippets to `~/.ai-dev-setup/` → adds one include block to each shell profile. Agent markdown management is opt-in; when requested, the installer creates or updates only its managed blocks in global Claude Code and Codex instruction files.

`cleanup-dev-tools-config.ps1` is a temporary maintenance script for the current debug cycle. Do not treat it as a permanent part of the repo design; delete it once installer behavior has been validated.

## Preferred CLI Tools

These are installed globally and should be used instead of their fallbacks:

- **rg** over `grep` — respects `.gitignore`
- **fd** over `find`
- **jq** for JSON, **yq** for YAML/TOML/XML — never parse structured data with grep/sed/awk
- **gh** for all GitHub operations (PRs, issues, CI)
- **fzf** when user selection from a list is needed

```bash
mise list       # see installed tools and versions
mise upgrade    # update all tools
```

## Agent Behavior Principles

1. **Don't assume. Don't hide confusion. Surface tradeoffs.**
   Ask clarifying questions instead of guessing formats, scope, or constraints.

2. **Minimum code that solves the problem. Nothing speculative.**
   Avoid premature abstraction and over-engineering.

3. **Touch only what you must. Clean up only your own mess.**
   Keep diffs small, reviewable, and trustworthy.

4. **Define success criteria. Loop until verified.**
   Write tests, check results, and iterate until the goal is demonstrably met.

## Shell Targets

Scripts must work in Git Bash on Windows. PowerShell variants (`.ps1`) exist for Windows-native contexts. WSL is not required or assumed.
