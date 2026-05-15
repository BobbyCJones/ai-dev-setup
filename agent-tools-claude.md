# Agent Guidance

Tools below are installed globally via mise. Use them when they add capability beyond Claude Code's built-in file, search, and edit tools.

## Preferred CLI tools

Installed globally via mise. Prefer them when they fit the task:

- Search: `sg` (ast-grep) for structural code search when text search is too broad
- Structured data: `jq` (JSON), `yq` (YAML/TOML/XML), `mlr` (CSV/TSV) — don't parse with `grep`/`sed`/`awk`
- GitHub: `gh` for PRs, issues, CI, releases (over raw `git` or `curl`)
- Azure: `az`, plus `az devops`/`pipelines`/`repos`/`boards` from the `azure-devops` extension
- SQL Server / Azure SQL: `sqlcmd` (`-Q` ad-hoc, `-i` script files)
- HTTP / API testing: `curl`
- Shell scripts: `shellcheck` (resolve warnings or document intentional suppressions), `shfmt -w` (format)
- `direnv` — do **not** modify `.envrc` without explicit instruction

## Context budget

Start bounded, expand deliberately. Unbounded tool output wastes context.

- Inspect with `git status --short`, `git diff --name-only`, then targeted `git diff -- <path>`
- Use `gh pr list --limit 20 --json number,title,url` over unfiltered dumps
- `az devops` defaults are pre-configured to `https://dev.azure.com/dwhomes/` / `IS-Aligned` by `install-dev-tools.ps1`; pass `--org` / `--project` only when intentionally working outside them. If `az boards` errors with a missing-org/project message, run `az devops configure --list` to diagnose
- `az boards query`: bound results with `--query "[0:20].id" -o tsv`; it does not support `--fields`
- `az boards work-item show`: use `--fields` only with `--expand none`, e.g. `az boards work-item show --id <id> --expand none --fields System.Id,System.Title`, or pipe full output to `jq`
- `az boards work-item relation add --relation-type`: use the **friendly name** (`"Parent"`, `"Child"`) not the reference name (`System.LinkTypes.Hierarchy-Reverse`). Run `az boards work-item relation list-type` to discover available names.
- Read only the files needed for the task

## Behavior principles

1. **Don't assume. Don't hide confusion. Surface tradeoffs.** Ask rather than guess at formats, scope, or constraints.
2. **Minimum code that solves the problem. Nothing speculative.** No premature abstraction.
3. **Touch only what you must. Clean up only your own mess.** Small, reviewable diffs.
4. **Define success criteria. Loop until verified.**

## Change tracking

**Commits.** Subject describes the change. Add a body only when context isn't obvious from the diff. One commit per logical change — don't bundle unrelated cleanups, refactors, or docs into a feature commit. If staging is mixed, split before committing. Stage explicit paths or hunks; avoid `git add .` unless the working tree contains only that commit's concern.

**Fork -> upstream PRs.** When the repo has a separate upstream remote (e.g., `Upstream-DWH`):
1. Resolve the upstream repository as `OWNER/REPO`; `gh --repo` does not accept git remote names:
   `gh repo view <upstream-owner>/<upstream-repo> --json defaultBranchRef --jq '.defaultBranchRef.name'`
2. Push to origin, then create the PR targeting upstream. Always quote `--head` because branch names with `#` or other shell metacharacters can be parsed incorrectly:
   `gh pr create --repo <upstream-owner>/<upstream-repo> --head "<fork-owner>:<branch>" --base <default-branch> --title "..." --body "..."`
3. If `gh pr create --repo` fails, use the API directly:
   `gh api repos/<upstream-owner>/<upstream-repo>/pulls --method POST --field head="<fork-owner>:<branch>" --field base="<default-branch>" --field title="..." --field body="..."`
4. Add reviewers separately:
   `gh api repos/<upstream-owner>/<upstream-repo>/pulls/<number>/requested_reviewers --method POST --field "reviewers[]=<username>"`

**PRs.** When you create or materially contribute to one, include:

```markdown
## AI Assistance

- Agent/tool: <name if known>
- Task: <short request summary>
- Changes: <main areas changed>
- Validation: <commands run, or not run with reason>
- Risks/review focus: <known risks, assumptions, or areas needing attention>
```

**Safety.** No secrets, credentials, tokens, private prompts or private transcripts, or speculative claims. No file-level provenance headers.
