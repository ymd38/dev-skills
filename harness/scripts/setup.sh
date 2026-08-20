#!/usr/bin/env bash
# dev-skills harness installer (non-interactive).
# No language auto-detection by design: pass --langs explicitly, or --minimal
# to install only the mechanical rails and decide languages later via /dev-skills-setup.
set -euo pipefail

HARNESS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATES="$HARNESS_ROOT/templates"

usage() {
  cat <<'EOF'
Usage:
  setup.sh (--langs go,python,typescript,javascript | --minimal) [options]

Required (one of):
  --langs LIST      Comma-separated languages. First entry is the primary.
                    Supported: go, python, typescript, javascript
  --minimal         Install hooks + settings + rules only (no CLAUDE.md).
                    Fill the stack later with /dev-skills-setup in Claude Code.

Options:
  --target DIR      Target project directory (default: current directory)
  --name NAME       Project name for CLAUDE.md (default: target dir name)
  --branch NAME     Default branch (default: main)
  --pm PM           Node package manager: pnpm | npm | yarn | bun (default: pnpm)
  --python-pm PM    Python package manager: uv | pip | poetry (default: uv)
  --guard-pip       Enable the "use uv, not pip install" bash guard
  --with-skills     Also run: npx skills add ymd38/dev-skills
  --force           Overwrite existing files (default: keep existing)
  -h, --help        Show this help
EOF
}

# ── Args ─────────────────────────────────────
TARGET="$PWD"
LANGS=""
MINIMAL=0
NAME=""
BRANCH="main"
PM="pnpm"
PY_PM="uv"
GUARD_PIP=0
WITH_SKILLS=0
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)     TARGET="$2"; shift 2 ;;
    --langs)      LANGS="$2"; shift 2 ;;
    --minimal)    MINIMAL=1; shift ;;
    --name)       NAME="$2"; shift 2 ;;
    --branch)     BRANCH="$2"; shift 2 ;;
    --pm)         PM="$2"; shift 2 ;;
    --python-pm)  PY_PM="$2"; shift 2 ;;
    --guard-pip)  GUARD_PIP=1; shift ;;
    --with-skills) WITH_SKILLS=1; shift ;;
    --force)      FORCE=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "error: unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$LANGS" && "$MINIMAL" != "1" ]]; then
  echo "error: --langs is required (e.g. --langs go,typescript), or pass --minimal" >&2
  usage >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"
[[ -z "$NAME" ]] && NAME="$(basename "$TARGET")"

IFS=',' read -r -a LANG_ARR <<<"$LANGS"
for l in "${LANG_ARR[@]:-}"; do
  case "$l" in
    go|python|typescript|javascript|"") ;;
    *) echo "error: unsupported language: $l (supported: go, python, typescript, javascript)" >&2; exit 1 ;;
  esac
done

case "$PM" in pnpm|npm|yarn|bun) ;; *) echo "error: unsupported --pm: $PM" >&2; exit 1 ;; esac
case "$PY_PM" in uv|pip|poetry) ;; *) echo "error: unsupported --python-pm: $PY_PM" >&2; exit 1 ;; esac

echo "==> dev-skills harness → $TARGET"

# ── Status trackers for the final checklist ──
ST_HOOKS=""
ST_SETTINGS=""
ST_CLAUDE=""
ST_RULES=""
ST_SKILLS="skipped (use --with-skills or: npx skills add ymd38/dev-skills)"

mkdir -p "$TARGET/.claude/hooks" "$TARGET/.claude/rules"

# ── Hooks ────────────────────────────────────
installed=0 kept=0
for f in post-write-format.sh pre-bash-guard.sh stop-suggest-cycle.sh session-start-context.sh; do
  src="$TEMPLATES/hooks/$f"
  dst="$TARGET/.claude/hooks/$f"
  if [[ -f "$dst" && "$FORCE" != "1" ]]; then
    kept=$((kept + 1))
  else
    cp "$src" "$dst"
    chmod +x "$dst"
    installed=$((installed + 1))
  fi
done
ST_HOOKS="installed=$installed kept=$kept"

# ── settings.json (create or merge hooks) ────
SETTINGS="$TARGET/.claude/settings.json"
if [[ ! -f "$SETTINGS" || "$FORCE" == "1" ]]; then
  cp "$TEMPLATES/settings.json.template" "$SETTINGS"
  ST_SETTINGS="created"
elif command -v jq >/dev/null 2>&1; then
  tmp="$(mktemp)"
  jq -s '
    (.[0].hooks // {}) as $cur | (.[1].hooks // {}) as $tpl |
    .[0] + {hooks: (
      ($cur | to_entries) + ($tpl | to_entries)
      | group_by(.key)
      | map({key: .[0].key, value: (map(.value) | add | unique_by(tostring))})
      | from_entries
    )}
  ' "$SETTINGS" "$TEMPLATES/settings.json.template" >"$tmp"
  mv "$tmp" "$SETTINGS"
  ST_SETTINGS="merged (existing hooks preserved)"
else
  ST_SETTINGS="SKIPPED — exists and jq unavailable; merge the hooks block from templates/settings.json.template manually"
fi

# Enable the pip guard via settings env when requested
if [[ "$GUARD_PIP" == "1" ]]; then
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    jq '.env = ((.env // {}) + {DEV_SKILLS_GUARD_PIP: "1"})' "$SETTINGS" >"$tmp"
    mv "$tmp" "$SETTINGS"
    ST_SETTINGS="$ST_SETTINGS + pip guard enabled"
  else
    echo "warn: --guard-pip needs jq to edit settings.json; add {\"env\":{\"DEV_SKILLS_GUARD_PIP\":\"1\"}} manually" >&2
  fi
fi

# ── Rules ────────────────────────────────────
RULES="$TARGET/.claude/rules/dev-skills-cycle.md"
if [[ -f "$RULES" && "$FORCE" != "1" ]]; then
  ST_RULES="kept existing"
else
  cp "$TEMPLATES/rules/dev-skills-cycle.md" "$RULES"
  ST_RULES="installed"
fi

# ── CLAUDE.md ────────────────────────────────
node_block() { # $1: TypeScript|JavaScript
  local lang="$1" run exec_cmd
  case "$PM" in
    pnpm) run="pnpm" exec_cmd="pnpm exec" ;;
    npm)  run="npm"  exec_cmd="npx" ;;
    yarn) run="yarn" exec_cmd="yarn" ;;
    bun)  run="bun"  exec_cmd="bunx" ;;
  esac
  printf '### %s (%s)\n' "$lang" "$PM"
  printf -- '- Install: `%s install`\n' "$run"
  printf -- '- Test: `%s test`\n' "$run"
  printf -- '- Lint: `%s run lint`\n' "$run"
  [[ "$lang" == "TypeScript" ]] && printf -- '- Typecheck: `%s tsc --noEmit`\n' "$exec_cmd"
  printf -- '- Format: Prettier (hook on Write/Edit)\n'
}

python_block() {
  printf '### Python (%s)\n' "$PY_PM"
  case "$PY_PM" in
    uv)
      printf -- '- Install: `uv sync`\n- Test: `uv run pytest`\n- Lint / Format: `uv run ruff check` / `uv run ruff format` (format hook on Write/Edit)\n' ;;
    pip)
      printf -- '- Install: `pip install -e .`\n- Test: `pytest`\n- Lint / Format: `ruff check` / `ruff format` (format hook on Write/Edit)\n' ;;
    poetry)
      printf -- '- Install: `poetry install`\n- Test: `poetry run pytest`\n- Lint / Format: `poetry run ruff check` / `poetry run ruff format` (format hook on Write/Edit)\n' ;;
  esac
}

go_block() {
  printf '### Go\n- Install: `go mod download`\n- Test: `go test ./...`\n- Lint: `golangci-lint run` (fallback: `go vet ./...`)\n- Format: goimports / gofmt (hook on Write/Edit)\n'
}

lang_title() {
  case "$1" in
    go) echo "Go" ;;
    python) echo "Python" ;;
    typescript) echo "TypeScript" ;;
    javascript) echo "JavaScript" ;;
  esac
}

CLAUDE_MD="$TARGET/CLAUDE.md"
if [[ "$MINIMAL" == "1" ]]; then
  ST_CLAUDE="skipped (--minimal) — run /dev-skills-setup in Claude Code to fill the stack"
elif [[ -f "$CLAUDE_MD" && "$FORCE" != "1" ]]; then
  ST_CLAUDE="kept existing — run /dev-skills-setup in Claude Code to merge the cycle section"
else
  primary="$(lang_title "${LANG_ARR[0]}")"
  others=""
  if [[ ${#LANG_ARR[@]} -gt 1 ]]; then
    for l in "${LANG_ARR[@]:1}"; do
      t="$(lang_title "$l")"
      others="${others:+$others, }$t"
    done
  fi
  STACK_BLOCKS="Primary: $primary"
  [[ -n "$others" ]] && STACK_BLOCKS+=$'\n'"Also present: $others"
  STACK_BLOCKS+=$'\n'
  for l in "${LANG_ARR[@]}"; do
    STACK_BLOCKS+=$'\n'
    case "$l" in
      go)         STACK_BLOCKS+="$(go_block)" ;;
      python)     STACK_BLOCKS+="$(python_block)" ;;
      typescript) STACK_BLOCKS+="$(node_block TypeScript)" ;;
      javascript) STACK_BLOCKS+="$(node_block JavaScript)" ;;
    esac
    STACK_BLOCKS+=$'\n'
  done

  {
    while IFS= read -r line; do
      if [[ "$line" == "{{STACK_BLOCKS}}" ]]; then
        printf '%s\n' "$STACK_BLOCKS"
      else
        line=${line//\{\{PROJECT_NAME\}\}/$NAME}
        line=${line//\{\{DEFAULT_BRANCH\}\}/$BRANCH}
        printf '%s\n' "$line"
      fi
    done <"$TEMPLATES/CLAUDE.md.template"
  } >"$CLAUDE_MD"
  ST_CLAUDE="created ($primary${others:+ + $others})"
fi

# ── Skills ───────────────────────────────────
if [[ "$WITH_SKILLS" == "1" ]]; then
  if command -v npx >/dev/null 2>&1; then
    if (cd "$TARGET" && npx --yes skills add ymd38/dev-skills); then
      ST_SKILLS="installed via npx skills add"
    else
      ST_SKILLS="FAILED — run manually: npx skills add ymd38/dev-skills"
    fi
  else
    ST_SKILLS="SKIPPED — npx not found; run manually: npx skills add ymd38/dev-skills"
  fi
fi

# ── Checklist ────────────────────────────────
cat <<EOF

[dev-skills harness]
  target:     $TARGET
  hooks:      $ST_HOOKS
  settings:   $ST_SETTINGS
  rules:      $ST_RULES
  CLAUDE.md:  $ST_CLAUDE
  skills:     $ST_SKILLS
  next:       open the project in Claude Code, then try "/software-evaluation ." — or "/dev-skills-setup" to refine commands interactively
EOF
