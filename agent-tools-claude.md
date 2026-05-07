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
- Use `az boards query --wiql "<WIQL>" --query "[0:20].id" -o tsv` and request only needed fields with `--fields`
- Read only the files needed for the task

## Behavior principles

1. **Don't assume. Don't hide confusion. Surface tradeoffs.** Ask rather than guess at formats, scope, or constraints.
2. **Minimum code that solves the problem. Nothing speculative.** No premature abstraction.
3. **Touch only what you must. Clean up only your own mess.** Small, reviewable diffs.
4. **Define success criteria. Loop until verified.**

## Change tracking

**Commits.** Subject describes the change. Add a body only when context isn't obvious from the diff. One commit per logical change — don't bundle unrelated cleanups, refactors, or docs into a feature commit. If staging is mixed, split before committing. Stage explicit paths or hunks; avoid `git add .` unless the working tree contains only that commit's concern.

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
