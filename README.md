# Agent Skills

A collection of AI agent skills for software engineering workflows — code quality reviews, living documentation, and security audits. Built for developers and engineering teams who want Claude Code to apply expert-level analysis to their codebases.

**Contributions welcome!** Have a skill to add or improvements to suggest? [Open a PR](#contributing).

## What are Skills?

Skills are Markdown files that give AI agents specialized knowledge, workflows, and output templates for specific tasks. When installed, Claude Code recognizes relevant requests and applies the skill automatically — no manual prompting required.

## Available Skills

| Skill | Description |
|-------|-------------|
| [spec-doc](skills/spec-doc/SKILL.md) | Generate or sync a "Living Specification" from source code to eliminate doc-code drift. Use when creating, updating, or reviewing architecture documentation for a directory or module. |
| [software-evaluation](skills/software-evaluation/SKILL.md) | Evaluate code quality across five pillars (Architecture, Reliability, Observability, Security, DX) and produce a 1–10 scorecard with a strategic improvement roadmap. |
| [vulnerability-scan](skills/vulnerability-scan/SKILL.md) | Run an OWASP-based offensive security audit using Semgrep and produce a read-only vulnerability report with severity ratings and remediation recommendations. |

## Installation

### Option 1: CLI Install (Recommended)

```bash
npx skills add ymd38/dev-skills
```

This automatically installs all skills to your project's `.claude/skills/` directory.

To install a single skill:

```bash
npx skills add ymd38/dev-skills --skill spec-doc
```

### Option 2: Manual Copy

Copy any skill directory into your project:

```bash
cp -r skills/spec-doc .claude/skills/spec-doc
```

Or copy all skills at once:

```bash
cp -r skills/* .claude/skills/
```

### Option 3: Git Submodule

Add as a submodule to keep skills up to date with upstream changes:

```bash
git submodule add https://github.com/ymd38/dev-skills.git .claude/dev-skills
```

Then reference skills from `.claude/dev-skills/skills/`.

## Usage

Once installed, describe your task naturally and the relevant skill is applied automatically:

```
"Generate a spec for src/api/"
→ Uses spec-doc skill

"Review the code quality of src/backend/"
→ Uses software-evaluation skill

"Scan src/ for security vulnerabilities"
→ Uses vulnerability-scan skill
```

You can also invoke skills directly:

```
/spec-doc src/
/software-evaluation src/backend/
/vulnerability-scan src/
```

## Skill Categories

### Documentation
- `spec-doc` — Generates a machine-readable "Living Specification" (`docs/spec.md`) from source code. Covers architecture, interfaces, data models, state transitions, and development constraints. Syncs with existing specs rather than replacing them.

### Code Quality
- `software-evaluation` — Scores a codebase across five pillars with evidence-based findings (file:line citations required). Produces a prioritized roadmap with P0–P3 action items.

### Security
- `vulnerability-scan` — Combines automated Semgrep scanning with a manual review checklist covering OWASP Top 10. Triages true positives from false positives and includes a dependency CVE audit.

## Contributing

Found a way to improve a skill? Have a new one to add? PRs and issues welcome.

**To add a new skill:**

1. Run `python init_skill.py <skill-name> --path skills/`
2. Edit `skills/<skill-name>/SKILL.md` — fill in `description` and the skill body
3. Remove unused `scripts/`, `references/`, `assets/` directories if created
4. Validate with `python package_skill.py skills/<skill-name>`
5. Add a row to the table in this README

## License

[MIT](LICENSE)
