---
name: dev-skills-setup
description: "Install the full dev-skills harness into the current project through a short interview: CLAUDE.md, hooks, .claude/settings.json, rules, and skill wiring. Asks — never auto-detects — the languages (Go / Python / TypeScript / JavaScript) and commands, then writes files only after an approved summary. Use when the user asks to set up / install / bootstrap dev-skills, the harness, or the continuous improvement cycle. Triggers: セットアップして, ハーネスを入れて, harnessを入れて, dev-skillsを導入して, プロジェクトを初期化して, '/dev-skills-setup', 'set up the harness', 'install dev-skills', 'bootstrap this project'."
---

# dev-skills Full Harness Setup (Interview Mode)

## Goal

Turn the current repository into a project that runs the
**Diagnose → Register/Draft → Plan → Resolve ⇄ Verify** cycle with
mechanical guardrails (hooks) and a lean CLAUDE.md.

Skills alone are L1. This setup adds L2–L3: a short project brain
(CLAUDE.md), hard rails (hooks + settings), and cycle guidance (rules).
It never creates scheduled loops or CI automation (L4) — that is out of
scope unless the user explicitly asks in a separate task.

## Principles

- **Interview, no auto-detection.** Do NOT infer languages from `go.mod`,
  `package.json`, etc., even when they exist. This setup targets
  pre-development projects where detection misleads. File existence is
  used only for overwrite/merge prompts.
- **Never overwrite** existing CLAUDE.md / settings / hooks without
  explicit per-file approval. Prefer merge (append missing sections).
- Hooks enforce hard rules; CLAUDE.md holds soft guidance. Keep
  CLAUDE.md short — detail lives in skills and `.claude/rules/`.
- Write files **only after** the user approves the Phase 4 summary.

## Workflow

Ask one phase at a time and wait for answers. If the user says
"use defaults", still require the primary language choice, then apply
the defaults table below to everything else.

### Phase 0 — Preconditions

1. Confirm the target is a git repository (offer `git init` if not).
2. Check existence (existence only — do not read to guess the stack) of:
   `CLAUDE.md`, `.claude/settings.json`, `.claude/hooks/`,
   `.claude/rules/dev-skills-cycle.md`, `.claude/skills/`.
3. Tell the user: existing files will each get an overwrite/merge/skip
   question in Phase 3.

### Phase 1 — Project skeleton (required)

- **Q1. Project name** — propose the directory name as default.
- **Q2. Primary language (choose exactly one):**
  Go / Python / TypeScript / JavaScript.
- **Q3. Additional languages** — none, or any others from the same list.
- **Q4. Default branch** — propose `main`.

### Phase 2 — Per-language commands

Ask for the primary language in full; for additional languages a quick
confirm of the defaults is enough. Propose these defaults:

| Language        | Install            | Test                | Lint                                          | Format (hook)                  |
| --------------- | ------------------ | ------------------- | --------------------------------------------- | ------------------------------ |
| Go              | `go mod download`  | `go test ./...`     | `golangci-lint run` (fallback `go vet ./...`) | `goimports` (fallback `gofmt`) |
| Python (uv)     | `uv sync`          | `uv run pytest`     | `uv run ruff check`                           | `uv run ruff format`           |
| Python (pip)    | `pip install -e .` | `pytest`            | `ruff check`                                  | `ruff format`                  |
| Python (poetry) | `poetry install`   | `poetry run pytest` | `poetry run ruff check`                       | `poetry run ruff format`       |
| TypeScript      | `{pm} install`     | `{pm} test`         | `{pm} run lint`                               | Prettier                       |
| JavaScript      | `{pm} install`     | `{pm} test`         | `{pm} run lint`                               | Prettier                       |

- Node projects: ask the package manager first (pnpm / npm / yarn / bun;
  propose pnpm), then substitute `{pm}`.
- TypeScript only: also ask about typecheck (`{pm} exec tsc --noEmit` /
  a script name / none).
- Python only: ask the package manager (uv / pip / poetry; propose uv).
  If uv, ask: "Enable a hook that blocks `pip install` in favor of
  `uv add`?" (Y/n).

### Phase 3 — Harness scope

- **Q-H1. Components** (multi-select, all recommended ON by default):
  CLAUDE.md / skills (`npx skills add ymd38/dev-skills`) /
  format hook / bash-guard hook / SessionStart + Stop guidance hooks /
  `.claude/rules/dev-skills-cycle.md` /
  GitHub Actions CI (`ci.yml` per language + `security-scan.yml` +
  `.gitleaks.toml`; secret scan gates from day one, trivy/semgrep start
  as informational `continue-on-error`) /
  .env guard (`.gitignore` entries + `.env.example`).
- **Q-H2. Per existing file**: merge (append only the missing sections) /
  back up then replace / skip.
- **Q-H3. Bash guard strength**: standard (rm -rf /, force-push to the
  default branch, redirects into `.env`) / standard + pip guard (uv
  projects) / none.

### Phase 4 — Confirm, then apply

Show a summary of every answer and every file that will be created or
modified. Wait for explicit approval. On approval, apply as follows.

**Preferred path — run the installer, then refine:**

1. Locate `harness/scripts/setup.sh`:
   - in this repo if it _is_ dev-skills or contains a clone/submodule, else
   - fetch via the official one-liner (network required):

     ```bash
     curl -fsSL https://raw.githubusercontent.com/ymd38/dev-skills/main/harness/scripts/install.sh \
       | bash -s -- --langs <langs> --pm <pm> --python-pm <py-pm> --branch <branch> --name <name> [--guard-pip] [--with-skills]
     ```

   Map answers to flags: languages (primary first) → `--langs`,
   Node PM → `--pm`, Python PM → `--python-pm`, pip guard → `--guard-pip`,
   skills component ON → `--with-skills`, CI component OFF → `--no-ci`.
   The installer never overwrites existing files, which is exactly the
   merge-safe behavior wanted here.

2. Then reconcile whatever the installer reported as "kept existing"
   against the user's Phase 3 answers:
   - CLAUDE.md kept + user chose **merge** → append only the missing
     sections (Stack & commands for the chosen languages, the cycle
     section, Hard rules), following `harness/templates/CLAUDE.md.template`.
   - settings kept unmerged (no jq) → merge the `hooks` block by hand,
     preserving every existing user hook.
   - Any file the user chose to **skip** → leave untouched even if the
     installer would have created it (delete nothing; just don't add).
3. Adjust generated CLAUDE.md commands to any non-default answers from
   Phase 2 (e.g. a custom test script name).

**Fallback (no network, no local copy):** report that the harness
templates are unavailable and stop after writing only what can be
written faithfully from this document — do not improvise hook scripts
from memory.

### Phase 5 — Verify and report

Print a final checklist:

```
[dev-skills harness]
  skills:     OK (N) / MISSING
  CLAUDE.md:  CREATED / MERGED / SKIPPED
  hooks:      OK (4 scripts, executable)
  settings:   OK / MERGED / needs manual merge
  rules:      OK / skipped
  next:       restart Claude Code to load hooks, then try /software-evaluation .
```

Remind the user that hooks load at session start — a restart (or new
session) is needed before the guard/format hooks take effect.

## Stop conditions

- User declines the Phase 4 summary → stop after reporting what _would_
  have changed. Write nothing.
- User declines an overwrite → keep the file, note it in the checklist.
- Unknown/other language requested → set up the supported languages,
  leave a `# TODO` stack block for the rest, and say so.

## Non-goals

- No scheduled loops, cron, or GitHub Actions (L4) — separate task only.
- No Semgrep / gh installation — mention prerequisites, don't install.
- No rewriting of existing architecture docs or unrelated refactors.
