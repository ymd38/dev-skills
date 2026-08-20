# Python rules (generic)

Language-level rules aligned with the evaluation pillars (see
`coding-principles.md` for tags). Framework-specific conventions belong in
your own project rules once the stack is decided.

- Type-hint every public function; keep `ruff check` and `ruff format`
  clean (CI enforces both). [DX]
- Never `except:` bare or `except Exception: pass`. Catch the specific
  exception, add context, and re-raise with `raise NewError(...) from err`
  when translating. [REL]
- Manage resources with context managers (`with`) — files, connections,
  locks; no manual close in happy-path-only code. [REL]
- Use the `logging` module with structured `extra={}` fields (request id,
  operation) — never `print()` outside CLIs. [OBS]
- No mutable default arguments (`def f(x, acc=[])` is a bug). [REL]
- Validate external data at the boundary with dataclasses/pydantic-style
  models; the core receives typed, valid values. [SEC][ARC]
- Database access is parameterized only — never f-string SQL. [SEC]
- `subprocess` without `shell=True` when any input is interpolated. [SEC]
- Prefer `pathlib.Path` over string paths. [DX]
- Small isolated `pytest` tests; shared setup via fixtures, not
  copy-paste. The first test lands with the first code PR (CI fails on
  zero tests by design). [DX]
