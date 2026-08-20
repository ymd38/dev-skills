# Continuous improvement cycle

- Diagnosis skills (`yds-software-evaluation`, `yds-vulnerability-scan`, `yds-data-validation`)
  produce evidence; they never silently rewrite the codebase.
- Implementation requires an agreed plan comment from `yds-gh-issue-planner`
  (`<!-- gh-issue-planner:agreed-plan -->`).
- `yds-gh-issue-resolver` may fix **regression** findings only, ≤3 iterations,
  within the plan's impact scope. Pre-existing findings → `yds-report-to-issues`
  after user approval — never fixed in the same PR.
- Never relax tests, types, or thresholds to greenwash a check.
