---
validated:
  sha: f072b4e5efd6fbf90b5ee724ed5b5882dcfc522b
  date: 2026-06-18T00:11:34Z
  reviewers: [fact-check, solid-hygiene]
  findings:
    critical: 0
    important: 0
    medium: 0
    low: 2
    nitpick: 1
  net_negative_remaining: 0
---

# CI Consolidation + Python Lint/Type Fixes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repo's Python pass `ruff`/`ruff format`/`mypy`, then fold those gates into the single `test.yml` workflow and delete the two redundant untracked workflows.

**Architecture:** Two ordered tasks. Task 1 cleans the Python (so the gates are green); Task 2 adds the gates to `test.yml` and removes the duplicates. Task 1 MUST land before Task 2 — adding the CI gates while the Python is dirty would make CI red.

**Tech Stack:** GitHub Actions (`test.yml`, macOS + Ubuntu matrix), ruff 0.8.4, mypy 1.13.0, pytest, bats, shellcheck.

**Spec:** `docs/superpowers/specs/2026-06-15-ci-consolidation-design.md` (blessed; one accepted net-negative — `mypy .` is intentionally unscoped, verified to check only the 3 first-party files).

## Global Constraints

- **Python 2.7 compatibility retained** — do NOT remove the `raw_input` shim; do NOT introduce Python-3-only syntax. (Spec: Py2 classifiers + `requires-python = ">=2.7"` stay.)
- **No `[tool.ruff]` / `[tool.mypy]` config** added to `pyproject.toml` — tool behavior stays in pinned versions + CLI invocations.
- **Tool versions pinned** in `.github/workflows/requirements-quality.txt`: `ruff==0.8.4`, `mypy==1.13.0`, `pytest==8.3.4`, `pytest-cov==6.0.0`.
- **`mypy . --ignore-missing-imports`** is used verbatim (unscoped `.`) — accepted; it checks only `dot.py`/`tests/` because `venv/` is not a package.
- **No Claude attribution in commits** (no `Co-Authored-By: Claude`, no `🤖 Generated with` footers).
- **Branch:** `chore/ci-consolidation` (already created, off `main`). Commit there; do not push to `main`.

---

### Task 1: Make the repo Python pass ruff / format / mypy (Py2.7-safe)

**Files:**
- Modify: `tests/conftest.py` (remove 2 unused imports)
- Modify: `tests/test_dotfiles.py` (remove 2 unused imports)
- Modify: `dot.py` (silence the one mypy error on the Py2 shim)
- Reformat: all three of the above via `ruff format`

**Interfaces:**
- Consumes: nothing.
- Produces: a Python tree where `ruff check .`, `ruff format --check .`, and `mypy . --ignore-missing-imports` all exit 0, and `pytest tests/` still passes. Task 2 relies on these gates being green.

- [ ] **Step 1: Confirm the gates currently fail (the "red" state)**

Run (activate the venv first):
```bash
source venv/bin/activate
ruff check .            # expect: 4 errors (F401 unused imports)
ruff format --check .   # expect: "3 files would be reformatted" (dot.py, conftest.py, test_dotfiles.py)
mypy . --ignore-missing-imports   # expect: 1 error — dot.py:20 Name "raw_input" is not defined
```
Expected: all three report the issues above. This is the baseline to fix.

- [ ] **Step 2: Remove the unused imports**

In `tests/conftest.py`, delete these two lines (currently lines 7–8):
```python
import tempfile
import shutil
```

In `tests/test_dotfiles.py`, delete the unused `import tempfile` (line 8) and `import pytest` (line 9). Keep `import os` / `import sys`. (ruff F401 confirms `pytest` is unreferenced — Step 5's pytest run re-verifies nothing broke.)

- [ ] **Step 3: Silence the mypy error on the Python-2 shim**

In `dot.py`, the shim is:
```python
try:
    input = raw_input  # Python 2
except NameError:
    pass  # Python 3
```
Change the `input = raw_input` line to add a targeted ignore (keeps the shim, satisfies mypy):
```python
    input = raw_input  # type: ignore[name-defined]  # Python 2
```

- [ ] **Step 4: Apply formatting**

Run: `ruff format .`
Expected: `3 files reformatted` (dot.py, tests/conftest.py, tests/test_dotfiles.py). This is a deterministic Black-style reformat (whitespace/quotes); it introduces no Python-3-only syntax, so Py2.7 compatibility is preserved.

- [ ] **Step 5: Verify all gates are green + tests still pass**

Run:
```bash
ruff check .                        # expect: "All checks passed!"
ruff format --check .               # expect: no files would be reformatted
mypy . --ignore-missing-imports     # expect: "Success: no issues found in 3 source files" (or no errors)
pytest tests/ -v                    # expect: all tests pass (confirms import removal was safe)
```
Expected: ruff/format/mypy clean; pytest green. If `pytest` import removal broke a test (it shouldn't — F401 means unreferenced), restore only the genuinely-used import and re-run.

- [ ] **Step 6: Commit**

```bash
git add dot.py tests/conftest.py tests/test_dotfiles.py
git commit -m "fix(python): drop unused imports, format, and silence Py2 raw_input shim for mypy"
```

---

### Task 2: Consolidate quality gates into test.yml; delete redundant workflows

**Files:**
- Modify: `.github/workflows/test.yml` (install from requirements file; add ruff/format/mypy steps)
- Add (commit the currently-untracked file): `.github/workflows/requirements-quality.txt`
- Delete (currently untracked — remove from working tree): `.github/workflows/python-quality.yml`, `.github/workflows/shellcheck.yml`

**Interfaces:**
- Consumes: the green gates from Task 1 (ruff/format/mypy pass on the repo).
- Produces: a single CI workflow that runs shellcheck → ruff check → ruff format check → mypy → pytest → validation bats → benchmark bats, on macOS + Ubuntu.

- [ ] **Step 1: Point the dependency install at the pinned requirements file**

In `.github/workflows/test.yml`, replace the existing step:
```yaml
      - name: Install Python dependencies
        run: |
          python -m pip install --upgrade pip
          pip install pytest pytest-cov
```
with:
```yaml
      - name: Install Python dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r .github/workflows/requirements-quality.txt
```
(`requirements-quality.txt` pins `ruff`, `mypy`, `pytest`, `pytest-cov` — so this one install covers the new gates and the existing pytest step.)

- [ ] **Step 2: Add the three quality steps after the ShellCheck step**

In `.github/workflows/test.yml`, immediately after the existing `Run ShellCheck linting` step and before `Run Python tests`, insert:
```yaml
      - name: Lint with ruff
        run: ruff check .

      - name: Format check with ruff
        run: ruff format --check .

      - name: Type check with mypy
        run: mypy . --ignore-missing-imports
```
These have no `if:` guard, so they run on **both** matrix legs (macOS + Ubuntu) — per the spec's accepted simplicity tradeoff.

- [ ] **Step 3: Track the requirements file; delete the redundant workflows**

Run (the two workflows are untracked, so a plain `rm` removes them — no `git rm` needed):
```bash
rm -f .github/workflows/python-quality.yml .github/workflows/shellcheck.yml
git add .github/workflows/requirements-quality.txt .github/workflows/test.yml
git status --short .github/workflows/
```
Expected: `test.yml` modified (`M`), `requirements-quality.txt` added (`A`), and `python-quality.yml` / `shellcheck.yml` gone from the tree (no longer listed as `??`).

- [ ] **Step 4: Validate the workflow YAML + dry-run the gate commands locally**

Run:
```bash
python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/test.yml')); print('test.yml: valid YAML')"
# the exact commands CI will now run (must be clean after Task 1):
source venv/bin/activate
ruff check . && ruff format --check . && mypy . --ignore-missing-imports && echo "all quality gates green"
```
Expected: `test.yml: valid YAML`; `all quality gates green`.

- [ ] **Step 5: Confirm only test.yml remains and it contains the new steps**

Run:
```bash
ls .github/workflows/                       # expect: requirements-quality.txt  test.yml
grep -E 'ruff check|ruff format --check|mypy \. --ignore-missing-imports|requirements-quality\.txt' .github/workflows/test.yml
```
Expected: only `test.yml` + `requirements-quality.txt` present; all four grep patterns found.

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/test.yml .github/workflows/requirements-quality.txt
git commit -m "ci: consolidate ruff/format/mypy into test.yml; drop redundant workflows"
```

> **Design note (2026-06-17):** Deleting `shellcheck.yml` removes a gate that `test.yml` does
> NOT replicate: a "global ShellCheck disables FORBIDDEN" policy step that fails CI if a script
> carries a top-of-file `# shellcheck disable=` directive (forcing per-line disables instead),
> plus an advisory script-executability check. The shellcheck *linting* coverage is fully
> preserved (test.yml's `find .` scope is a superset of `.claude/**`), so only that policy gate
> is retired. This is an intentional, documented consequence of the blessed spec's deletion —
> not an oversight. If the no-blanket-disable policy is worth keeping, fold its one `grep`-based
> guard into `test.yml`'s ShellCheck step as a follow-up (out of scope for this plan).

---

## Notes for the implementer

- **Order is load-bearing:** Task 1 (clean Python) before Task 2 (enforce gates). Running Task 2 first would make CI red.
- **The real proof is CI:** after both tasks, push the branch and confirm `test.yml` is green on macOS + Ubuntu (shellcheck → ruff → format → mypy → pytest → bats). Local dry-runs in the steps above are the pre-push check.
- **`requirements-quality.txt` already exists untracked** with the right pins; Task 2 just tracks it. Do not rewrite it.
- **Keep commits attribution-free** (Global Constraints).
- The full `bats tests/` suite should also stay green (it's unaffected), but `test.yml` only runs `test-validate.bats` + `test-benchmark.bats`.
- **Local `ruff`/`mypy` may resolve to pyenv shims** (newer versions) rather than the pinned `0.8.4`/`1.13.0`; only CI (`pip install -r requirements-quality.txt`) guarantees the pins. The baselines match across versions here, but if you want the local dry-runs to exactly mirror CI, `pip install -r .github/workflows/requirements-quality.txt` into the venv first.
