# Agent Guidance

These tools are installed globally via mise. Use them to extend Claude Code's built-in file, search, and edit tools.

## Preferred CLI tools

- Shell search: `rg` (over `grep`), `fd` (over `find`) — use in Bash commands and scripts; prefer built-in Grep/Glob tools for agent file operations
- Structural code search: `sg` (ast-grep) when text search is too broad
- Structured data: `jq` (JSON), `yq` (YAML/TOML/XML), `mlr` (CSV/TSV) — don't parse with `grep`/`sed`/`awk`
- GitHub: `gh` for PRs, issues, CI, releases (over raw `git` or `curl`)
- SQL Server / Azure SQL: `sqlcmd` (`-Q` ad-hoc, `-i` script files)
- HTTP / API testing: `curl`
- Shell scripts: `shellcheck` (resolve warnings or document intentional suppressions), `shfmt -w` (format)
- `direnv` — do **not** modify `.envrc` without explicit instruction

## Context budget

Start bounded, expand deliberately. Unbounded tool output wastes context.

- Inspect with `git status --short`, `git diff --name-only`, then targeted `git diff -- <path>`
- Use `rg -l <pattern>` and `rg -n --max-count 20 <pattern>` to cap matches
- Use `gh pr list --limit 20 --json number,title,url` over unfiltered dumps
- Read only the files needed for the task

## Behavior principles

1. **Make reasonable assumptions and proceed; state them clearly.** Ask only when ambiguity blocks progress. Don't hide confusion. Surface tradeoffs.
2. **Minimum code that solves the problem. Nothing speculative.** No premature abstraction.
3. **Touch only what you must. Clean up only your own mess.** Small, reviewable diffs.
4. **Define success criteria. Loop until verified.**

## Writing standards

Apply to all documentation and agent instruction files:

- **Every word adds value.** Cut ruthlessly.
- **Active voice, definitive statements.** Avoid: "may," "currently," "designed to," "where possible."
- **Each fact appears once.** Cross-reference; never repeat.
- **Simple language, short sentences.** No jargon. One concept per sentence.
- **No defensive language.** Avoid: "(for now)," "(currently limited)," qualifiers that weaken statements.
- **Structure for scannability.** Clear headings, short paragraphs.

## Change tracking

**Azure DevOps tickets.** Use `/ado-ticket <parent-id>` to create a child work item.

**Branches.** Name branches using the ADO ticket number prefixed with `AB#`: `AB#1234`.

**Commits.** Subject describes the change. Add a body only when context isn't obvious from the diff. One commit per logical change — don't bundle unrelated cleanups, refactors, or docs into a feature commit. If staging is mixed, split before committing. Stage explicit paths or hunks; avoid `git add .` unless the working tree contains only that commit's concern.

**Fork → upstream PRs.** Use `/fork-pr` when the repo has a separate upstream remote.

**PRs.** When you create or contribute to a PR, include:

```markdown
## AI Assistance

- Agent/tool: <name if known>
- Task: <short request summary>
- Changes: <main areas changed>
- Validation: <commands run, or not run with reason>
- Risks/review focus: <known risks, assumptions, or areas needing attention>
```

**Safety.** No secrets, credentials, tokens, private prompts or private transcripts, or speculative claims. No file-level provenance headers.
