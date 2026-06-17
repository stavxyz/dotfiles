---
validated:
  sha: 42dd6ed3d9bb3c22402efc5dd2cb45b17655177c
  date: 2026-06-17T21:26:10Z
  reviewers: [fact-check, solid-hygiene]
  findings:
    critical: 0
    important: 2
    medium: 1
    low: 1
    nitpick: 0
  net_negative_remaining: 1
---

# Design: CI consolidation + Python lint/type fixes

**Date:** 2026-06-15
**Status:** Approved
**Branch:** chore/ci-consolidation

## Goal

One coherent CI workflow (`test.yml`) that lints, type-checks, and tests with zero
redundancy, and a repo whose Python passes `ruff` / `ruff format` / `mypy` — while keeping
the project's existing Python 2.7 support.

## Background

Three workflow files exist; two are untracked WIP and overlap the tracked `test.yml`:

- **`test.yml`** (tracked, active CI) — on push/PR to `main`, macOS + Ubuntu matrix:
  `find .`-based shellcheck, `pytest tests/`, `bats tests/test-validate.bats`, `bats tests/test-benchmark.bats`.
- **`python-quality.yml`** (untracked) — `ruff check`, `ruff format --check`, `mypy`,
  `pytest` + coverage on a 3.11/3.12 matrix. Its `pytest` **duplicates** `test.yml`.
- **`shellcheck.yml`** (untracked) — shellcheck limited to `.claude/**`; **redundant** with
  `test.yml`'s broader `find .` shellcheck.

The repo's Python (only `dot.py`, `tests/conftest.py`, `tests/test_dotfiles.py`) currently
fails the quality gates: 4 unused imports (ruff F401), 3 files need formatting, and `mypy`
flags `raw_input` — the intentional Python-2 compatibility shim in `dot.py`. `pyproject.toml`
declares `requires-python = ">=2.7"` with Py2 classifiers; Python 2 support is **retained**
(operator decision).

## Design

### Python fixes (all Python-2.7-safe)

1. `tests/conftest.py` — remove unused `import tempfile`, `import shutil`.
2. `tests/test_dotfiles.py` — remove unused `import tempfile`, `import pytest`. Re-run the
   suite afterward to confirm `pytest` was genuinely unreferenced (ruff F401 says so).
3. `dot.py` — add `# type: ignore[name-defined]` to the `input = raw_input` line. Keeps the
   Py2 shim; silences the sole mypy error.
4. `ruff format` the three files (Black-style whitespace/quote normalization — introduces no
   Python-3-only syntax, so Py2.7 compatibility is preserved).

No `[tool.ruff]` / `[tool.mypy]` config is added — the workflow invocations (`ruff check .`,
`ruff format --check .`, `mypy . --ignore-missing-imports`) plus tool defaults suffice.
Py2 classifiers and `requires-python` are left untouched.

### CI consolidation (single workflow: `test.yml`)

1. In `test.yml`, install the quality tools from the existing `requirements-quality.txt`
   (already pins `ruff==0.8.4`, `mypy==1.13.0`, `pytest==8.3.4`, `pytest-cov==6.0.0`) instead
   of the current inline `pip install pytest pytest-cov`.
2. Add three steps after the existing ShellCheck step, **on both matrix OSes** (macOS +
   Ubuntu — results are OS-independent, so running on both is harmless and keeps the matrix
   uniform):
   - `ruff check .`
   - `ruff format --check .`
   - `mypy . --ignore-missing-imports`
3. The existing `pytest`, validation, and benchmark steps stay.
4. **Delete** `python-quality.yml` (pytest duplicates `test.yml`) and `shellcheck.yml`
   (redundant with `test.yml`'s `find .` shellcheck). These are untracked, so deletion = `rm`.
5. **Keep** `requirements-quality.txt` (now consumed by `test.yml`).

### Result

A single CI workflow runs: shellcheck → ruff check → ruff format check → mypy → pytest →
validation bats → benchmark bats, on macOS + Ubuntu. No duplicated pytest, no redundant
shellcheck.

> **Accepted net-negative tradeoff (2026-06-17):** The design hard-codes `mypy .` (with no
> `[tool.mypy]` scoping) into the canonical `test.yml`, which a reviewer flagged as relying on
> mypy's package-walk defaults rather than an explicit scope. Accepted with explicit operator
> approval: verified that `mypy . --ignore-missing-imports` checks only the 3 first-party files
> ("checked 3 source files") because `venv/` is not a Python package and is therefore not
> recursed; the minimal, config-free scope is intentional for a 3-file Python surface.

> **Design note (2026-06-17):** Tool configuration is deliberately kept out of `pyproject.toml`
> (no `[tool.ruff]`/`[tool.mypy]`); behavior lives in the pinned tool versions
> (`requirements-quality.txt`) plus the CLI invocations in `test.yml`. If a third Python file,
> a per-rule ignore, or a `target-version` is ever needed, `pyproject.toml` is the place to
> centralize it — the consolidation doesn't preclude that, it just doesn't pre-build it (YAGNI).

> **Design note (2026-06-17):** Running ruff/format/mypy on both matrix legs (macOS + Ubuntu)
> duplicates OS-independent work; this is an accepted simplicity tradeoff (uniform, branch-free
> matrix) for a tiny repo. If CI minutes ever matter, factor the OS-independent quality checks
> into a single-runner job.

## Testing

Locally, all green before pushing:
- `ruff check .` → clean
- `ruff format --check .` → clean
- `mypy . --ignore-missing-imports` → clean
- `pytest tests/ -v` → pass (confirms the import removals didn't break tests)
- `bats tests/` → pass
- `shellcheck` over the repo's shell scripts → clean
Then confirm the consolidated `test.yml` is green on the PR (macOS + Ubuntu).

## Scope / YAGNI

- Python 2 support retained (no shim removal, no classifier/`requires-python` changes).
- No new lint/type configuration in `pyproject.toml`.
- No reformatting of non-Python files.
- The CI workflow audit is limited to these three files; no changes to the bats suites or
  the test harness beyond installing tools from `requirements-quality.txt`.
