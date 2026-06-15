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
  `find .`-based shellcheck, `pytest tests/`, `bats test-validate.bats`, `bats test-benchmark.bats`.
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
