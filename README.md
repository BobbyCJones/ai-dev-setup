# Dev Environment Setup

Sets up a Windows developer machine with universal CLI tools, safer git defaults, a repo-owned global mise fragment, and repo-managed shell snippets for agent-assisted development. Run once per machine.

## Prerequisites

- Windows 10/11 with [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) (App Installer)
- [Claude Code](https://claude.ai/code) installed and authenticated
- [Codex](https://github.com/openai/codex) and/or [Cursor](https://www.cursor.com/) (optional)
- Internet access

> `git` and `curl` are also required but are typically already present. If not, install git with `winget install Git.Git` before continuing.

## Quick Start

**Agent-assisted (recommended):**

```bash
# Claude Code
claude "Read the README.md and set up my dev environment following the instructions"

# Codex
codex "Read the README.md and set up my dev environment following the instructions"
```

For Cursor: open this folder, launch Composer (`Ctrl+I`), and send the same prompt.

**Manual:**

```powershell
.\install-dev-tools.ps1
```

The installer configures Azure DevOps CLI defaults for `https://dev.azure.com/dwhomes/` and `IS-Aligned` so `az boards`, `az pipelines`, and `az repos` work from GitHub checkouts. To leave existing Azure DevOps defaults untouched:

```powershell
.\install-dev-tools.ps1 -SkipAzureDevOpsDefaults
```

See [mise-setup.md](mise-setup.md) for the detailed walkthrough and verification steps.

## Global Machine Setup

Run this once per machine from this repo:

```powershell
.\install-dev-tools.ps1
```

What the installer does globally:

1. Installs `mise` if it is not already present.
2. Installs the CLI tools declared in [mise.toml](mise.toml) so they are available in any terminal.
3. Installs a repo-owned global mise fragment under `%APPDATA%\\mise\\conf.d`.
4. Copies managed shell snippets to `%USERPROFILE%\\.ai-dev-setup`.
5. Adds one include block to PowerShell profiles and `~/.bashrc` so shell activation works automatically.
6. Configures conservative global git defaults, including `delta` for syntax-highlighted diffs when available.

After installation, open a new shell and verify:

```bash
mise list
rg --version
delta --version
gh auth status
```

Result: the toolchain is installed and configured globally for your user account. New terminals should have the managed shell integration and globally installed tools available without additional setup in this repo.

## Project Repo Setup

The machine-level setup gives you the shared toolchain globally. Individual project repos still need their own runtime and environment configuration.

In each project repo:

1. Add a `mise.toml` at the repo root to pin the runtimes that project needs.
2. Run `mise install` in that repo to install the versions declared there.
3. Add a `.envrc` for project-local environment variables, then run `direnv allow`.
4. Commit a `.envrc.example` template and add `.envrc` to `.gitignore`.
5. Optionally add `AGENTS.md` or `CLAUDE.md` for project-specific agent instructions.

Example project `mise.toml`:

```toml
[tools]
node   = "20"
python = "3.12"
```

Example project onboarding flow:

```bash
git clone <repo>
cd <repo>
cp .envrc.example .envrc
# fill in .envrc with real values
direnv allow
mise install
```

See [project-setup.md](project-setup.md) for the fuller per-project template and examples.

## What This Sets Up

| File | Purpose |
|------|---------|
| [mise.toml](mise.toml) | Canonical global tool manifest used by `mise install` in this repo |
| [managed-config/](managed-config) | Repo-owned mise and shell snippets installed under user config directories |
| [mise-setup.md](mise-setup.md) | Machine setup guide and verification steps |
| [project-setup.md](project-setup.md) | What to add to each project repo |
| [agent-tools-claude.md](agent-tools-claude.md) | Claude Code-specific template for global `CLAUDE.md` instructions |
| [agent-tools.md](agent-tools.md) | Codex/generic CLI template for global `AGENTS.md` instructions |

## Installed Tools

All tools are installed globally via [mise](https://mise.jdx.dev) and available in any terminal.

| Tool | Replaces | What it does |
|------|----------|--------------|
| [rg](https://github.com/BurntSushi/ripgrep) (ripgrep) | `grep` | Fast file content search; respects `.gitignore` automatically |
| [fd](https://github.com/sharkdp/fd) | `find` | Simple, fast file discovery; respects `.gitignore` |
| [jq](https://jqlang.github.io/jq/) | `grep`/`awk` on JSON | JSON parsing and transformation from the command line |
| [yq](https://github.com/mikefarah/yq) | — | YAML, TOML, and XML — same query syntax as `jq` |
| [gh](https://cli.github.com/) | `curl` to GitHub API | PRs, issues, CI status, releases — all GitHub operations |
| [mlr](https://miller.readthedocs.io/) (miller) | `awk`/`cut` on CSV | CSV and TSV processing — same pipeline design as `jq` |
| [sg](https://ast-grep.github.io/) (ast-grep) | `rg` for code patterns | Structural code search and replace using AST patterns, not text |
| [shellcheck](https://www.shellcheck.net/) | — | Lints shell scripts; catches portability bugs and common mistakes |
| [shfmt](https://github.com/mvdan/sh) | — | Formats shell scripts consistently |
| [sqlcmd](https://github.com/microsoft/go-sqlcmd) | — | SQL Server and Azure SQL query runner |
| [az](https://github.com/Azure/azure-cli) (Azure CLI) | `curl` to Azure APIs | Provision and manage Azure resources from the terminal; includes the `azure-devops` extension |
| [bat](https://github.com/sharkdp/bat) | `cat` | File display with syntax highlighting and line numbers |
| [eza](https://github.com/eza-community/eza) | `ls` | Directory listings with git status per file |
| [fzf](https://github.com/junegunn/fzf) | — | Interactive fuzzy selection from any list |
| [direnv](https://direnv.net/) | — | Project-scoped environment variables via `.envrc` |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `cd` | Smarter directory jumping based on frecency |
| [delta](https://github.com/dandavison/delta) | — | Syntax-highlighted git diffs |

## Why These Tools

Most developer machines ship with `grep`, `find`, `cat`, and `ls`. They work, but they were designed for a different era. The tools installed here are modern replacements that are faster, safer, and composable — and they make a measurable difference both when you're working alone and when you're working with an AI agent.

**Search that stays out of your way**

`rg` and `fd` respect `.gitignore` by default. You never accidentally search `node_modules`, build output, or vendored dependencies. On a large repo, this is the difference between a result in milliseconds and one in seconds — and between two results and two thousand.

**Structured data you can actually use**

Config files, API responses, and log output are almost always JSON, YAML, TOML, or CSV. Parsing those with `grep` and `awk` is fragile — it breaks on whitespace, nested keys, and arrays. `jq`, `yq`, and `mlr` parse the structure correctly and let you query, transform, and reshape data in a single readable pipeline.

**Code changes that are precise, not approximate**

`sg` (ast-grep) understands code syntax, not just text. When you need to find every call to a function, rename a method across a codebase, or locate all imports of a module, text search produces false positives. `sg` matches the AST — it finds exactly what you mean regardless of whitespace or formatting differences.

**Shell scripts that don't come back to haunt you**

`shellcheck` catches portability bugs, quoting mistakes, and common errors that only surface on a different OS or shell version. `shfmt` formats scripts consistently. Running both before committing a script costs seconds and prevents the kind of subtle breakage that costs hours.

**GitHub without the browser**

`gh` covers the full GitHub workflow from the terminal: opening PRs, checking CI status, reading and posting comments, managing releases. Staying in the terminal keeps context — no tab switching, no copy-pasting URLs.

**Better diffs, less friction**

`delta` replaces the default git diff output with syntax-highlighted, side-by-side diffs. Code review in the terminal becomes readable. `bat` does the same for individual files — syntax highlighting and line numbers everywhere `cat` used to be plain text.

**For AI agents specifically**

All of the above applies when an AI agent is doing the work, but Claude Code and Codex need slightly different global instructions. This repo installs `agent-tools-claude.md` into global `CLAUDE.md` and `agent-tools.md` into global `AGENTS.md` when `-InstallAgentTemplates` is used. Claude Code keeps its built-in file/search/edit workflow, while Codex and generic CLI agents get bounded shell command guidance. The practical result: agents search faster, parse data correctly, make precise code changes, and write shell scripts that pass review — without you having to prompt it each session.

## Ownership Boundaries

- This setup **does** install tools from the repo's [mise.toml](mise.toml).
- This setup **does** install a repo-owned global mise fragment under `%APPDATA%\mise\conf.d`.
- This setup **does** install repo-managed shell snippets under `%USERPROFILE%\.ai-dev-setup`.
- This setup **does** add one include block to PowerShell profiles and `~/.bashrc`.
- This setup **does not** overwrite `%APPDATA%\mise\config.toml`.
- This setup **does not** overwrite user content in `~/.claude/CLAUDE.md` or `~/AGENTS.md`; with `-InstallAgentTemplates`, it creates or updates only the repo-managed blocks.

## Re-running

Safe to re-run at any time. Managed shell snippets are recopied, include blocks are only added once, and existing user-owned config is preserved where possible.
