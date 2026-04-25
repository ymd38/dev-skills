---
name: gh-issue-resolver
description: "Implement and verify a fix for a GitHub Issue whose response plan has already been posted as a comment by gh-issue-planner. Creates a feature branch, applies the agreed plan, runs tests, and opens a Pull Request. Use when the user asks to implement/fix/resolve a planned GitHub Issue. Triggers include requests such as Issueを実装して / Issueを修正して / Issueを対応して, implement issue #N, fix issue #N, resolve issue #N, work on issue #N. Prerequisite: an agreed plan comment must exist on the issue (run gh-issue-planner first if not)."
---

# GitHub Issue Resolver

## Overview

Implement and verify a fix for a GitHub Issue, starting from the agreed response plan that `gh-issue-planner` has already posted as a comment on the issue. This skill creates a feature branch, applies the agreed changes, runs tests, opens a Pull Request, and verifies the fix against the original issue.

## Prerequisites

- The target issue must have an **agreed plan comment** previously posted by `gh-issue-planner`, identified by the HTML marker `<!-- gh-issue-planner:agreed-plan -->` near the end of the comment body.
- If no such comment exists, **stop and direct the user to run `gh-issue-planner` first**. Do not improvise an unagreed plan in this skill.

## Workflow

### Step 1: Fetch the Issue and Agreed Plan

Run the following command (replace `<id>` with the issue number):

```bash
gh issue view <id> --json number,title,body,labels,state,url,comments
```

From the `comments` array:
1. Locate the most recent comment whose body contains the marker `<!-- gh-issue-planner:agreed-plan -->`.
2. Treat that comment as the **agreed plan** and extract the 対応方針 / 影響範囲 / 実装方法 sections.
3. If no such comment exists, abort with a message asking the user to run `gh-issue-planner` first.

### Step 2: Branch Strategy

```bash
# Create a feature branch from the default branch
git checkout -b fix/<id>-<short-description>
# Examples: fix/42-add-timeout-to-fetch, feat/15-user-export-api
```

Branch naming convention:
- Bug fixes: `fix/<id>-<short-description>`
- Features: `feat/<id>-<short-description>`
- Refactors: `refactor/<id>-<short-description>`

### Step 3: Implementation

Apply the changes defined in the agreed plan. Follow these rules:
- Make minimal, focused changes — do not scope-creep beyond the agreed plan
- Run existing tests after each logical change to catch regressions early
- Add or update tests to cover the changed behavior
- If the agreed plan turns out to be infeasible or incomplete, **stop and return to `gh-issue-planner`** rather than silently expanding the scope here

### Step 4: Test Verification

```bash
# Run tests relevant to the changed area
# Ensure no regressions in existing tests
# Verify new tests pass
```

If tests fail, diagnose and fix before proceeding. Do not skip failing tests.

### Step 5: Create a Pull Request

```bash
gh pr create --title "<type>(#<id>): <short description>" --body "$(cat <<'EOF'
## Summary
<What was changed and why — reference the issue>

Closes #<id>

## Changes
- <file>: <what changed>
- <file>: <what changed>

## Testing
- [ ] Existing tests pass
- [ ] New tests added for changed behavior
- [ ] Manual verification completed
EOF
)"
```

### Step 6: Verify

After implementation, verify the fix addresses the original issue:

1. **Re-read the issue description and acceptance criteria** — does the implementation fully address them?
2. **Run the full test suite** — no regressions introduced
3. **If the issue originated from `software-evaluation` or `vulnerability-scan`:** suggest re-running the relevant skill on the changed files to confirm the finding is resolved

```
✅ Implementation complete for Issue #<id>.

To verify the improvement, consider re-running:
  /software-evaluation <changed-path>
  /vulnerability-scan <changed-path>
```

This closes the improvement cycle loop — the next diagnosis will confirm the fix.

## Key Principles

- **Never start implementation without an agreed plan comment** posted by `gh-issue-planner`
- Stay strictly within the agreed plan — no scope creep
- Never skip or weaken failing tests; fix the root cause instead
- Prefer minimal, upstream fixes over downstream workarounds
