---
description: Create a pull request from a fork to an upstream GitHub repository
allowed-tools: [Bash]
---

# Fork → Upstream Pull Request

## Context at invocation

- Remotes: !`git remote -v`
- Current branch: !`git branch --show-current`
- Push status: !`git status -sb`

## Procedure

### 1. Resolve upstream OWNER/REPO

Identify the upstream remote — any remote that is not `origin`. Parse its URL to extract `OWNER/REPO`.

If exactly one non-origin remote exists, use it. If multiple exist, list them and ask the user to pick one.

Get the default branch:

```
gh repo view <OWNER/REPO> --json defaultBranchRef --jq '.defaultBranchRef.name'
```

Then ask: "Base branch? [default: `<resolved>`]". Use the answer in `--base`.

`gh --repo` does not accept git remote names — resolve to `OWNER/REPO` first.

### 2. Resolve fork owner

```
gh repo view --json owner --jq '.owner.login'
```

### 3. Check for an existing open PR

`gh pr list --head` does not support `owner:branch` syntax. Filter by branch name and author separately:

```
gh pr list --repo <upstream-OWNER/REPO> --head "<branch>" --author "<fork-owner>" --state open --json number,url
```

If one exists, report the URL and stop.

### 4. Prepare title and body

- Propose a title from the branch name and `git log --oneline -5`
- If the branch matches `AB#\d+`, include `AB#<number>` in the body
- Fill the AI Assistance template from conversation context:

```
## AI Assistance

- Agent/tool: <name if known>
- Task: <from conversation context>
- Changes: <from commit log / diff>
- Validation: <commands run, or reason if not run>
- Risks/review focus: <from what you know>
```

### 5. Ask for reviewers and draft mode

Ask for GitHub usernames (accept a list or skip). Also ask: "Draft PR? (y/N)".

### 6. Confirm before creating

Show the draft title, body, base branch, reviewers, and draft status. Wait for confirmation.

### 7. Push branch

```
git push -u origin <branch>
```

### 8. Create PR

Always quote `--head` — branch names with `#` break shell parsing. Include `--draft` if requested. Include reviewers via `--reviewer` if any were given:

```
gh pr create --repo <upstream-OWNER/REPO> --head "<fork-owner>:<branch>" --base <base-branch> --title "..." --body "..." [--draft] [--reviewer <handle>]
```

Capture the output — it contains the PR URL. Extract the PR number from the trailing path segment of the URL.

If `gh pr create` fails due to reviewer permissions (fork PRs may not allow `--reviewer`), retry without it:

```
gh pr create --repo <upstream-OWNER/REPO> --head "<fork-owner>:<branch>" --base <base-branch> --title "..." --body "..." [--draft]
```

If `gh pr create` fails entirely, fall back to the API:

```
gh api repos/<upstream-OWNER/REPO>/pulls --method POST --field head="<fork-owner>:<branch>" --field base="<base-branch>" --field title="..." --field body="..." --field draft=<true|false>
```

The API response is JSON. Extract the PR number from `.number`.

### 9. Add reviewers (if not added at create)

If `--reviewer` succeeded in Step 8, skip this step. Otherwise, add reviewers using the captured PR number:

```
gh api repos/<upstream-OWNER/REPO>/pulls/<number>/requested_reviewers --method POST --field "reviewers[]=<username>"
```

### 10. Report

Print the PR URL.
