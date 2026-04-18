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

See [mise-setup.md](mise-setup.md) for step-by-step instructions.

## What This Sets Up

| File | Purpose |
|------|---------|
| [mise.toml](mise.toml) | Canonical global tool manifest used by `mise install` in this repo |
| [managed-config/](managed-config) | Repo-owned mise and shell snippets installed under user config directories |
| [mise-setup.md](mise-setup.md) | Machine setup guide and verification steps |
| [project-setup.md](project-setup.md) | What to add to each project repo |
| [agent-tools.md](agent-tools.md) | Optional template for global agent instructions |

## Installed Tools

All tools are installed globally via [mise](https://mise.jdx.dev) and available in any terminal.

| Tool | Replaces | What it does |
|------|----------|--------------|
| [rg](https://github.com/BurntSushi/ripgrep) (ripgrep) | `grep` | Fast file content search; respects `.gitignore` automatically |
| [fd](https://github.com/sharkdp/fd) | `find` | Simple, fast file discovery; respects `.gitignore` |
| [jq](https://jqlang.github.io/jq/) | `grep`/`awk` on JSON | JSON parsing and transformation from the command line |
| [yq](https://github.com/mikefarah/yq) | — | YAML, TOML, and XML — same query syntax as `jq` |
| [gh](https://cli.github.com/) | `curl` to GitHub API | PRs, issues, CI status, releases — all GitHub operations |
| [bat](https://github.com/sharkdp/bat) | `cat` | File display with syntax highlighting and line numbers |
| [eza](https://github.com/eza-community/eza) | `ls` | Directory listings with git status per file |
| [fzf](https://github.com/junegunn/fzf) | — | Interactive fuzzy selection from any list |
| [direnv](https://direnv.net/) | — | Project-scoped environment variables via `.envrc` |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `cd` | Smarter directory jumping based on frecency |
| [delta](https://github.com/dandavison/delta) | — | Syntax-highlighted git diffs |

## Ownership Boundaries

- This setup **does** install tools from the repo's [mise.toml](mise.toml).
- This setup **does** install a repo-owned global mise fragment under `%APPDATA%\mise\conf.d`.
- This setup **does** install repo-managed shell snippets under `%USERPROFILE%\.ai-dev-setup`.
- This setup **does** add one include block to PowerShell profiles and `~/.bashrc`.
- This setup **does not** overwrite `%APPDATA%\mise\config.toml`.
- This setup **does not** overwrite existing `~/.claude/CLAUDE.md` or `~/AGENTS.md`.

## Re-running

Safe to re-run at any time. Managed shell snippets are recopied, include blocks are only added once, and existing user-owned config is preserved where possible.
