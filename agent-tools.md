# Available CLI Tools

These tools are installed globally via mise. Use them instead of fallbacks.

## Search & Discovery

- **rg** (ripgrep) — prefer over `grep` for all file content search. Respects `.gitignore` automatically.
- **fd** — prefer over `find` for file discovery. Simpler syntax, respects `.gitignore`.

## Data Processing

- **jq** — use for all JSON parsing and transformation. Never parse JSON with `grep`, `sed`, or `awk`.
- **yq** — use for YAML, TOML, and XML. Same query syntax as `jq`.
- **mlr** (miller) — use for CSV and TSV data. Same pipeline-friendly design as `jq`. Never parse tabular data with `awk` or `cut`.

## Code Search & Refactoring

- **sg** (ast-grep) — use for structural code search and replace. Prefer over `rg` when matching code patterns (function calls, imports, type usage) where text search would be too broad or fragile.

## Shell Script Quality

- **shellcheck** — lint any shell script before considering it done. Run `shellcheck <script.sh>` and resolve all warnings.
- **shfmt** — format shell scripts with `shfmt -w <script.sh>`. Run after writing or editing any shell script.

## Database

- **sqlcmd** — use for querying SQL Server and Azure SQL databases. Run ad-hoc queries (`sqlcmd -S <server> -Q "SELECT ..."`) or execute `.sql` script files (`sqlcmd -S <server> -i script.sql`).
- **az** (Azure CLI) — use for all Azure resource operations: provisioning, querying resource state, managing credentials, and interacting with Azure services. Prefer over raw `curl` to Azure REST APIs. The `azure-devops` extension is installed: use `az devops`, `az pipelines`, `az repos`, and `az boards` for Azure DevOps operations.

## GitHub

- **gh** — use for all GitHub operations: creating PRs, commenting on issues, checking CI status, managing releases. Prefer over raw `git` commands or `curl` to the GitHub API.

## File Display

- **bat** — prefer over `cat` when showing file contents to the user. Includes syntax highlighting and line numbers.
- **eza** — prefer over `ls` for directory listings. Shows git status per file.

## HTTP

- **curl** — use for API testing, downloading files, and interacting with web services.

## Interactive Input

- **fzf** — use when you need the user to select from a list of options. Pipe choices to `fzf` and read the selection.

## Environment

- **direnv** — manages project-scoped environment variables. Do not modify `.envrc` files without explicit instruction from the user.

## Maintenance

```bash
mise list       # see all installed tools and their versions
mise upgrade    # update all tools to latest
mise outdated   # check what has updates available
```

## Agent Change Tracking

### Commit messages

Keep commit subjects focused on the actual code or documentation change. If you are the primary author of the change and extra context would help future readers, include a short commit body covering: agent/tool used, task summary, validation performed, and notable risks. Do not force provenance into every commit.

### PR descriptions

When you create or materially contribute to a PR, include this section in the description:

```markdown
## AI Assistance

- Agent/tool: <name if known>
- Task: <short request summary>
- Changes: <main areas changed>
- Validation: <commands run, or not run with reason>
- Risks/review focus: <known risks, assumptions, or areas needing attention>
```

### Safety

- Do not include secrets, credentials, private tokens, full prompts, chat transcripts, or speculative claims.
- Do not add file-level provenance headers.
