# Per-Project Setup

Complements the machine-level setup in [mise-setup.md](mise-setup.md). Add these files to individual project repos to pin tool versions and manage environment variables.

## Overview

The machine setup installs universal CLI tools globally. Per-project setup handles two separate concerns:

- **Runtime version pinning** — ensures all developers on a project use the same language version
- **Environment variable isolation** — keeps project secrets out of your shell profile and away from other projects

## 1. Pin Language Runtimes with `mise.toml`

Add a `mise.toml` to your project root to declare which runtime versions the project requires.

```toml
[tools]
node   = "20"
python = "3.12"
ruby   = "3.3"
```

When a developer enters the directory, mise automatically switches to these versions (if `mise activate` is in their shell profile, which the machine setup handles).

**Common runtimes:**

| Tool | Example |
|------|---------|
| Node.js | `node = "20"` |
| Python | `python = "3.12"` |
| Ruby | `ruby = "3.3"` |
| Go | `go = "1.22"` |
| Java | `java = "temurin-21"` |

Install the versions declared in `mise.toml`:

```bash
mise install
```

## 2. Manage Environment Variables with `.envrc`

Add a `.envrc` to your project root for environment variables that should only be active inside that directory.

```bash
export DATABASE_URL="postgres://localhost/myapp_dev"
export API_KEY="your-key-here"
export NODE_ENV="development"
```

Activate it once after creating or modifying:

```bash
direnv allow
```

direnv will automatically load these variables when you enter the directory and unload them when you leave.

**Important:** Never commit `.envrc` directly — it contains secrets. Commit a `.envrc.example` with placeholder values instead.

Add to your project's `.gitignore`:

```
.envrc
```

Commit a template:

```bash
# .envrc.example
export DATABASE_URL="postgres://localhost/myapp_dev"
export API_KEY=""
export NODE_ENV="development"
```

## 3. Per-Project Agent Instructions

For project-specific agent behavior, add an `AGENTS.md` or `CLAUDE.md` to the repo root. The machine setup includes separate starting points for Claude Code and Codex/generic CLI agents — copy the matching file and extend it with project-specific context.

```bash
# Claude Code
cp /path/to/dev-setup/agent-tools-claude.md ./CLAUDE.md

# Codex / generic CLI agents
cp /path/to/dev-setup/agent-tools.md ./AGENTS.md

# then add project-specific instructions below the copied template
```

## New Developer Onboarding

Once a project has `mise.toml` and `.envrc.example`, a new developer can be up and running with:

```bash
git clone <repo>
cd <repo>
cp .envrc.example .envrc
# fill in .envrc with real values
direnv allow
mise install
```
