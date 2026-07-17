---
description: Create an Azure DevOps child work item under an existing parent work item
allowed-tools: [mcp__azure-devops__wit_get_work_item, mcp__azure-devops__wit_create_work_item, mcp__azure-devops__wit_update_work_item, mcp__azure-devops__wit_work_items_link, Bash]
---

# Azure DevOps: Create Child Work Item

Parent work item ID: $ARGUMENTS

If no ID appears above, ask for it before starting.

## Step 1: Inspect parent

Use `wit_get_work_item` with the parent ID and `fields`:
`["System.Id", "System.Title", "System.WorkItemType", "System.AreaPath", "System.IterationPath", "System.AssignedTo", "Microsoft.VSTS.Common.Priority"]`

`System.AssignedTo` is an object — extract `uniqueName` for use as the assignee. If null or empty, omit assignee from the create call.

## Step 2: Gather inputs and draft content

Ask the user for all of the following before making any more API calls:

**Type** — work item type names are process-template-specific. This table is a reference for dwhomes/IS-Aligned:

| Parent type    | Standard child | Alternative child  |
|----------------|----------------|--------------------|
| Epic           | Feature        | —                  |
| Feature        | User Story     | Bug                |
| User Story     | Developer Task | Bug, Test Case     |
| Developer Task | —              | —                  |

**Title** — the child work item title.

**Priority** — 1 (Critical), 2 (High), 3 (Medium), 4 (Low).

**Sprint** — show the parent's iteration path and ask: use it, or specify a different one? If overriding, the user must supply the full path (e.g. `IS-Aligned\Sprint 42`).

Once those inputs are collected, draft:

- **Description** — 2-4 sentences explaining what the work item covers and why.
- **Acceptance criteria** — only for User Story and Bug. Skip for Developer Task, Feature, and Test Case. For User Story, focus on user-observable outcomes; for Bug, focus on reproduction and fix verification.

Present all drafts to the user and ask them to confirm, edit, or replace. Do not proceed until the user approves the content.

## Step 3: Create the child work item

Use `wit_create_work_item` with `workItemType` and a `fields` array. Every field — including title, area path, priority, and assignee — is a `{name, value}` object in that array. HTML fields also require `format: "Html"`.

Required fields:
- `{name: "System.Title", value: "<approved title>"}`
- `{name: "System.AreaPath", value: "<parent area path>"}`
- `{name: "System.IterationPath", value: "<chosen sprint path>"}`
- `{name: "Microsoft.VSTS.Common.Priority", value: "<1|2|3|4>"}`
- `{name: "System.Description", value: "<div><p>Approved description.</p></div>", format: "Html"}`

If assignee is not empty:
- `{name: "System.AssignedTo", value: "<uniqueName>"}`

For User Story and Bug only — do not set this field for any other type:
- `{name: "Microsoft.VSTS.Common.AcceptanceCriteria", value: "<div><ul><li>Criterion one.</li></ul></div>", format: "Html"}`

If any field could not be set during creation, use `wit_update_work_item` with JSON Patch format:
`updates: [{path: "/fields/System.Description", value: "<div>...</div>", op: "add"}]`

## Step 4: Link to parent

Use `wit_work_items_link` to establish a Parent/Child relationship:

```
updates: [{id: <CHILD_ID>, linkToId: <PARENT_ID>, type: "parent"}]
```

## Step 5: Verify and report

Use `wit_get_work_item` with `expand: "relations"` to confirm the parent relation is present. Report the child ID, title, and edit URL:

`https://dev.azure.com/dwhomes/IS-Aligned/_workitems/edit/<CHILD_ID>`

## Step 6: Create branch

Ask the user: "Create branch `AB#<CHILD_ID>` from the current branch?"

If yes:

```bash
git checkout -b "AB#<CHILD_ID>"
```

Report the branch name on success.
