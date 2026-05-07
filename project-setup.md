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

### Optional: Azure DevOps Work Item Workflow

If the project uses Azure DevOps for work tracking, add this block to your project's `AGENTS.md` or `CLAUDE.md` so agents can create and link tickets without re-deriving the workflow each session.

**Board constants for Product Development:**
- Org: `https://dev.azure.com/dwhomes/`
- Project: `IS-Aligned`
- Team: `Product Development`
- Team area path: `IS-Aligned\Product Development`
- `Big Job` backlog work item types: `Epic`, `Feature Proposal`

`Big Job` is a backlog level label, not automatically the child work item type. Inspect the parent and nearby work before choosing a child type.

**CLI quirks:**
- `az boards work-item show` does not accept `--project` — omit it
- When using `--fields` with `work-item show`, also pass `--expand none` or the CLI errors
- `az boards query` returns a list directly; bound results with `--query "[0:20].id"`
- There is no `az boards work-item type list`; use parent inspection, nearby work, or `az devops invoke` for type discovery
- Descriptions and acceptance criteria are stored as HTML — always pass HTML, not plain text

**Workflow:**
1. Inspect parent:
   `az boards work-item show --id <PARENT_ID> --org https://dev.azure.com/dwhomes/ --expand none --fields System.Id,System.Title,System.WorkItemType,System.AreaPath,System.IterationPath,System.AssignedTo,Microsoft.VSTS.Common.Priority -o json`
2. Inspect nearby Product Development work if the child type is unclear:
   `az boards query --org https://dev.azure.com/dwhomes/ --project IS-Aligned --wiql "SELECT [System.Id], [System.Title], [System.WorkItemType] FROM WorkItems WHERE [System.TeamProject] = 'IS-Aligned' AND [System.AreaPath] UNDER 'IS-Aligned\Product Development' ORDER BY [System.ChangedDate] DESC" --query "[0:20].id" -o tsv`
3. Create child with `az boards work-item create`, copying the appropriate area, iteration, assignee, priority, HTML description, and HTML acceptance criteria from the inspected context
4. Link to parent:
   `az boards work-item relation add --id <CHILD_ID> --relation-type parent --target-id <PARENT_ID> --org https://dev.azure.com/dwhomes/`
5. Verify:
   `az boards work-item show --id <CHILD_ID> --org https://dev.azure.com/dwhomes/ --expand relations`

**Recommended agent prompt template:**
```text
Create a child Azure DevOps ticket under parent work item <PARENT_ID>.
Inspect the parent with az boards work-item show and copy its area path,
iteration path, assignee, and priority. Inspect nearby Product Development
work before choosing the child work item type; do not infer type from the
Big Job backlog label alone. Create the work item with a clear title, HTML
description, and HTML acceptance criteria, then link it to the parent with
az boards work-item relation add --id <CHILD_ID> --relation-type parent
--target-id <PARENT_ID>. Return the new work item ID and edit URL.
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
