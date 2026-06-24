# Plan: Relocate Fork → Upstream PR Guidance to Per-Project Snippet

## Problem

The "Fork -> upstream PRs" block was added to `agent-tools-claude.md` and `agent-tools.md`,
which are injected globally into `~/.claude/CLAUDE.md` and `~/AGENTS.md`. This guidance only
applies to repos with a fork/upstream remote setup — loading it globally adds noise for every
other project.

The existing design already handles this correctly for ADO workflows: `project-setup.md` has
an "Optional: Azure DevOps Work Item Workflow" section with a snippet to paste into a project's
`CLAUDE.md`/`AGENTS.md`. The fork PR workflow should follow the same pattern.

## Goal

- Remove the fork PR block from the global agent-tools files
- Add it as an "Optional: Fork -> Upstream PR Workflow" snippet in `project-setup.md`
- Re-sync the global files via the installer
- Verify the result

## Steps

### 1. Remove from `agent-tools-claude.md`

Delete this block (currently before the `**PRs.**` paragraph):

```
**Fork -> upstream PRs.** When the repo has a separate upstream remote (e.g., `Upstream-DWH`):
1. Resolve the upstream repository as `OWNER/REPO`; `gh --repo` does not accept git remote names:
   `gh repo view <upstream-owner>/<upstream-repo> --json defaultBranchRef --jq '.defaultBranchRef.name'`
2. Push to origin, then create the PR targeting upstream. Always quote `--head` because branch names with `#` or other shell metacharacters can be parsed incorrectly:
   `gh pr create --repo <upstream-owner>/<upstream-repo> --head "<fork-owner>:<branch>" --base <default-branch> --title "..." --body "..."`
3. If `gh pr create --repo` fails, use the API directly:
   `gh api repos/<upstream-owner>/<upstream-repo>/pulls --method POST --field head="<fork-owner>:<branch>" --field base="<default-branch>" --field title="..." --field body="..."`
4. Add reviewers separately:
   `gh api repos/<upstream-owner>/<upstream-repo>/pulls/<number>/requested_reviewers --method POST --field "reviewers[]=<username>"`
```

### 2. Remove from `agent-tools.md`

Same block, same location.

### 3. Update `project-setup.md`

#### 3a. Add `--relation-type` friendly-name quirk to the CLI quirks list

`project-setup.md` already has a CLI quirks section (before the workflow steps) that lists az boards gotchas. The workflow's step 4 uses `--relation-type parent` correctly, but the requirement to use friendly names isn't documented there. Add this bullet to the CLI quirks list:

```
- `az boards work-item relation add --relation-type` takes the **friendly name** (`"Parent"`, `"Child"`), not the reference name (`System.LinkTypes.Hierarchy-Reverse`)
```

#### 3b. Add optional fork PR snippet after the ADO Workflow section

Add a new subsection after the existing "Optional: Azure DevOps Work Item Workflow" section:

```markdown
### Optional: Fork -> Upstream PR Workflow

If the project is a personal fork of an upstream org repo (e.g., `BobbyCJones/revittools` forked
from `davidweekleyhomes/revittools`), add this block to your project's `AGENTS.md` or `CLAUDE.md`
so agents know how to create PRs correctly without rediscovering the workflow each session.

**Fork -> upstream PRs.** When the repo has a separate upstream remote (e.g., `Upstream-DWH`):
1. Resolve the upstream repository as `OWNER/REPO`; `gh --repo` does not accept git remote names:
   `gh repo view <upstream-owner>/<upstream-repo> --json defaultBranchRef --jq '.defaultBranchRef.name'`
2. Push to origin, then create the PR targeting upstream. Always quote `--head` because branch names with `#` or other shell metacharacters can be parsed incorrectly:
   `gh pr create --repo <upstream-owner>/<upstream-repo> --head "<fork-owner>:<branch>" --base <default-branch> --title "..." --body "..."`
3. If `gh pr create --repo` fails, use the API directly:
   `gh api repos/<upstream-owner>/<upstream-repo>/pulls --method POST --field head="<fork-owner>:<branch>" --field base="<default-branch>" --field title="..." --field body="..."`
4. Add reviewers separately:
   `gh api repos/<upstream-owner>/<upstream-repo>/pulls/<number>/requested_reviewers --method POST --field "reviewers[]=<username>"`
```

Insert after line ~138 (end of the ADO Workflow section, closing ``` of the prompt template), before `## New Developer Onboarding`.

### 4. Run the installer

```powershell
.\install-dev-tools.ps1 -Yes -InstallAgentTemplates
```

### 5. Verify

Confirm the fork PR block is gone from both global files and the `az boards` quirks remain:

```powershell
# Should return nothing
Select-String "Fork ->" C:\Users\bcjones\.claude\CLAUDE.md
Select-String "Fork ->" C:\Users\bcjones\AGENTS.md

# Should still be present
Select-String "az boards work-item show" C:\Users\bcjones\.claude\CLAUDE.md
Select-String "az boards work-item show" C:\Users\bcjones\AGENTS.md
```

Confirm both additions landed in `project-setup.md`:

```powershell
# Fork PR snippet
Select-String "Fork -> Upstream PR Workflow" C:\GitHub\ai-dev-setup\project-setup.md

# relation-type quirk
Select-String "relation-type" C:\GitHub\ai-dev-setup\project-setup.md
```

## Files changed

| File | Change |
|------|--------|
| `agent-tools-claude.md` | Remove fork PR block |
| `agent-tools.md` | Remove fork PR block |
| `project-setup.md` | Add `--relation-type` quirk to CLI quirks list; add optional fork PR snippet section |
| `~/.claude/CLAUDE.md` | Updated by installer |
| `~/AGENTS.md` | Updated by installer |

## Out of scope

- The `az boards` quirk lines stay in the global files — `az devops` is configured machine-wide
  and the CLI gotchas apply to any project. This includes the `--relation-type` friendly-name
  requirement added to `agent-tools-claude.md` / `agent-tools.md` in the same session that
  prompted this plan. That quirk also gets added to `project-setup.md`'s CLI quirks list (step 3a)
  because that file has its own ADO-specific quirks section.
- No changes to `install-dev-tools.ps1`.
