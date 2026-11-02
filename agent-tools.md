# Agent Guidance

These tools are installed globally via mise. Use them instead of POSIX defaults.

## Preferred CLI tools

- Search / discovery (respect `.gitignore`): `rg` (over `grep`), `fd` (over `find`), `sg` (ast-grep) for structural code search when text search is too broad
- Structured data: `jq` (JSON), `yq` (YAML/TOML/XML), `mlr` (CSV/TSV) — don't parse with `grep`/`sed`/`awk`
- GitHub: `gh` for PRs, issues, CI, releases (over raw `git` or `curl`)
- SQL Server / Azure SQL: `sqlcmd` (`-Q` ad-hoc, `-i` script files)
- HTTP / API testing: `curl`
- Shell scripts: `shellcheck` (resolve warnings or document intentional suppressions), `shfmt -w` (format)
- `direnv` — do **not** modify `.envrc` without explicit instruction

## Inspecting unfamiliar .NET assembly APIs

Don't use `Assembly.LoadFrom`, `Add-Type`, or throwaway `dotnet run` probes to reflect on NuGet DLLs — the sandbox blocks loading and executing arbitrary assemblies. Write the call with a best-guess signature in the real project and run `dotnet build`. Roslyn's CS1061/CS1503/CS7036 diagnostics name the real member, parameter types, and order. Fall back to a raw byte/text scan of the DLL only when the method name itself is unknown.

## Where to run scripts

Build, test, and run scripts only under `C:\GitHub`, worktrees included. Never use the Claude session scratchpad (`AppData\Local\Temp\claude\...`), even when the harness names it for temp files. ThreatLocker blocked scripts and built test binaries there, and the machine owner confirmed that `C:\GitHub` runs. Put throwaway scripts and scratch builds in `C:\GitHub\.scratch`.

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

**Branches.** Name branches using the ADO ticket number prefixed with `AB#`: `AB#1234`.

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
