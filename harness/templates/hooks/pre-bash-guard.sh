#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash) — deny destructive or policy-breaking commands.
# Exit 0 with no output = no opinion (normal permission flow applies).
set -euo pipefail

command -v jq >/dev/null 2>&1 || { cat >/dev/null; exit 0; }

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
[[ -z "$cmd" ]] && exit 0

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

deny_patterns=(
  # Filesystem / system
  'rm -rf +/( |$)'
  'rm -rf +~'
  'rm -rf +\*'
  'mkfs\.'
  ':\(\)\{ *:\|:& *\};:'
  # Git history on shared branches
  'git push[^|;&]*(--force|-f)[^|;&]*(main|master)'
  # Databases (irreversible, no WHERE-clause escape hatch)
  'DROP +DATABASE'
  'TRUNCATE +TABLE'
  # Infrastructure / production (irreversible or wide-blast-radius)
  'terraform +destroy'
  'kubectl +delete +namespace'
  'kubectl +delete +[^|;&]*--all'
  'docker +system +prune'
  'docker +volume +prune'
  'aws +s3 +rb'
  'aws +s3 +rm +[^|;&]*--recursive'
  'gcloud +projects +delete'
)

for p in "${deny_patterns[@]}"; do
  if echo "$cmd" | grep -Eiq "$p"; then
    deny "Blocked by pre-bash-guard: matched /$p/. If this is intentional, ask the user to run it manually."
  fi
done

# Block shell redirects into .env files (secret exfiltration / clobbering)
if echo "$cmd" | grep -Eq '(>|>>) *[^ ]*\.env([^a-zA-Z0-9_.-]|$)'; then
  deny "Refusing shell redirect into a .env file. Edit env files explicitly with user approval."
fi

# Optional: enforce uv over pip (enabled by setup when the project uses uv)
# GUARD_PIP_MARKER — do not remove; setup.sh toggles the block below.
if [[ "${DEV_SKILLS_GUARD_PIP:-0}" == "1" ]]; then
  if echo "$cmd" | grep -Eq '(^|[ ;|&])pip3? +install'; then
    deny "This project uses uv. Use 'uv add <pkg>' (or 'uv pip install' inside the venv) instead of pip install."
  fi
fi

exit 0
