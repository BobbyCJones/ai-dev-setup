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
