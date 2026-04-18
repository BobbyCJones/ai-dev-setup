# Agent Runtime And Preference Test

Use this file to verify two things:

1. CLI agents can access the machine-level toolchain installed by this repo.
2. CLI agents are configured to prefer those tools through their global instruction files.

## Goal

Confirm that:

- Claude Code can access `rg`, `jq`, and `gh`
- Codex can access `rg`, `jq`, and `gh`
- the agent can see instruction content telling it to prefer `rg`, `fd`, `jq`, `yq`, `gh`, `bat`, `eza`, and `fzf`

The test must be run from a directory outside this repo so it validates machine-wide availability rather than repo-local behavior.

## Instructions For The Agent

1. Change to the user's home directory.
2. Confirm the current working directory is **not** this repository.
3. Run these commands and report their output:

```powershell
rg --version
jq --version
gh --version
```

4. Run these commands and report their output:

```powershell
where rg
where jq
where gh
```

5. Inspect the relevant global instruction file for the current agent:

- Claude Code: `%USERPROFILE%\.claude\CLAUDE.md`
- Codex: `%USERPROFILE%\AGENTS.md`

6. Report whether that file contains guidance to prefer these tools:

- `rg` over `grep`
- `fd` over `find`
- `jq` for JSON
- `yq` for YAML/TOML/XML
- `gh` for GitHub operations
- `bat` over `cat`
- `eza` over `ls`
- `fzf` for user selection from a list

7. Run one real tool-usage check:

```powershell
rg --files | rg README
```

8. State whether the environment passed based on these criteria:

- all three version commands succeeded
- all three `where` commands returned a path
- the `rg --files | rg README` command succeeded without command-not-found errors
- the current agent's global instruction file exists
- the current agent's global instruction file contains the tool-preference guidance listed above

## Prompt To Give The Agent

```text
Read agent-runtime-test.md and execute the test exactly as written. Report the command results and whether the environment passed.
```

## Expected Result

The agent should be able to run all commands successfully from the user's home directory or another directory outside this repo, and its global instruction file should explicitly prefer the installed tools.
