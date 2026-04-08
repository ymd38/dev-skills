---
name: gh-issue-resolver
description: "Fetch a GitHub Issue by ID using the gh CLI, investigate related code, and propose a structured response plan (policy, impact scope, implementation steps). Use when the user provides a GitHub Issue ID or asks to work on/analyze/fix a GitHub Issue. Triggers include issue IDs like #42 or 'issue 42', requests such as Issueを対応して, fix issue #N, investigate issue, look at issue, resolve issue, or any similar phrasing that references a specific GitHub Issue."
---

# GitHub Issue Resolver

## Overview

Fetch a GitHub Issue, analyze its content, investigate related code in the repository, then present a structured response plan to the user. Confirm any ambiguities before proceeding to implementation.

## Workflow

### Step 1: Fetch the Issue

Run the following command (replace `<id>` with the issue number):

```bash
gh issue view <id> --json number,title,body,labels,assignees,state,url,comments
```

If no repository context is clear, also run:

```bash
gh repo view --json nameWithOwner
```

Extract from the response:
- **Title** and **body**: the core problem statement
- **Labels**: bug / feature / enhancement / etc. — determines response approach
- **Comments**: additional context, workarounds, or constraints from stakeholders

### Step 2: Classify the Issue

Determine issue type to guide the investigation strategy:

| Label / Signal | Type | Investigation Focus |
|---|---|---|
| bug, error, crash | Bug fix | Error paths, edge cases, affected callers |
| feature, enhancement | New feature | Insertion points, interface contracts, related modules |
| refactor, tech-debt | Refactoring | Current usage sites, test coverage |
| docs, documentation | Docs update | Existing docs, code references |

### Step 3: Investigate Related Code

Extract keywords from the title and body, then search the codebase:

1. Use `code_search` with natural-language queries derived from the issue
2. Use `grep_search` for specific function/class/variable names mentioned
3. Use `read_file` to deeply understand the most relevant files
4. Trace call chains and dependencies to establish impact scope

Focus on:
- Files and functions directly mentioned or implied in the issue
- Callers / consumers of affected code
- Tests covering the affected area

### Step 4: Present the Response Plan

Present the following structured plan to the user in their preferred language:

```
## Issue #<id>: <title>

### 対応方針 (Approach)
<What will be done and why — 2-4 sentences>

### 影響範囲 (Impact Scope)
- **変更対象ファイル**: list of files to modify
- **影響を受けるモジュール**: related modules that may be affected
- **テスト**: existing tests to update + new tests to add

### 実装方法 (Implementation Steps)
1. <Concrete step>
2. <Concrete step>
3. ...

### 懸念事項・確認事項 (Open Questions)
- <Any ambiguity or assumption that needs user confirmation>
```

### Step 5: Confirm and Iterate

- If there are open questions, **ask the user before proceeding**
- Adjust the plan based on feedback
- Once the user explicitly confirms, proceed to Step 6

### Step 6: Post the Agreed Plan to the Issue

After the user confirms the plan, post it as a comment on the GitHub Issue:

```bash
gh issue comment <id> --body "$(cat <<'EOF'
## 対応方針

<agreed approach>

## 影響範囲

- **変更対象ファイル**: <files>
- **影響を受けるモジュール**: <modules>
- **テスト**: <tests>

## 実装方法

1. <step>
2. <step>

---
*このコメントはAIエージェントによって自動生成されました。*
EOF
)"
```

Then proceed to implementation.

## Key Principles

- **Never implement without confirmation** when open questions exist
- Keep the plan concise — avoid over-engineering
- If the issue is vague, ask one focused clarifying question rather than multiple at once
- Prefer minimal, upstream fixes over downstream workarounds
