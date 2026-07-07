# dot Extensions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make extensions a first-class concept of the dot system (host repo + dot.py), then migrate Claude Code config into a new private `stavxyz/dotfiles-private` extension.

**Architecture:** dot.py 1.1.0 gains two generic capabilities (manifest-relative source resolution, opt-in `--force-relink`) and stays extension-unaware. A new sourced library `lib/dot-extensions.sh` is the single owner of extension discovery, manifest picking, module loading, and bootstrap; `bash_profile` and `install.sh` both consume it. Extensions live at `~/.dot/extensions/<name>/` and are self-similar to the host repo.

**Tech Stack:** bash (3.2-compatible for install.sh/lib; 4.3+ for interactive modules), Python (dot.py, py2.7+-compatible style), pytest, bats, shellcheck.

**Spec:** `docs/superpowers/specs/2026-07-07-dot-extensions-design.md` (validated `498195a4`).

## Global Constraints

- `lib/dot-extensions.sh` and `install.sh` MUST run under macOS system bash 3.2 (no `mapfile`, no `${var,,}`, no associative arrays). Process substitution `< <(...)` is OK.
- Interactive modules and `bash_profile` target bash 4.3+ (existing requirement).
- dot.py stays zero-dependency, Python 2.7+-compatible style: `.format()` not f-strings, no type annotations in code.
- All shell files must pass `shellcheck` with no blanket disables (CI forbids a `# shellcheck disable` line not directly above the offending line).
- All modules sourced at shell startup must be ERR-trap-clean under `set -E` + `trap ERR`: never end a file or branch with a possibly-false bare conditional; use `if` statements.
- Python gate (CI-pinned): `ruff check .`, `ruff format --check .`, `mypy . --ignore-missing-imports`, `pytest tests/`. Tools live in `.github/workflows/requirements-quality.txt` (ruff 0.8.4, mypy 1.13.0, pytest 8.3.4).
- Commit messages: conventional-commit style (`feat(dot): ...`); NO Claude attribution / Co-Authored-By trailers.
- Work on branch `dot-extensions` off current `main`; finish with a PR, never merge to main directly.
- `~/.dot/` is dot's only home directory in `$HOME`: `state/`, `extensions/`.
- dot.py's existing behavior to preserve: targets that exist as regular files/dirs are hard refusals (abort); matching-source symlinks are skipped silently; `--yes`/`--no-confirm` semantics unchanged.

---

### Task 0: Branch and clean working tree

**Files:**
- No source changes. Branch setup only.

**Interfaces:**
- Produces: branch `dot-extensions` with a clean working tree at its tip; all later tasks commit onto it.

- [ ] **Step 1: Inspect and resolve any uncommitted changes**

```bash
cd ~/dotfiles && git status --short
```

Expected: possibly `M claude/settings.json` and/or `M git/gitconfig` (apps write through the symlinks — e.g. `gh` adds a credential helper to gitconfig, Claude Code rewrites settings.json). Review each diff (`git diff <file>`). These are legitimate machine-driven config updates: commit them to `main` first with message `chore(config): absorb app-written config updates`. If the tree is already clean, skip.

- [ ] **Step 2: Create the branch**

```bash
git checkout -b dot-extensions main
git status --short   # expected: empty
```

- [ ] **Step 3: No commit (branch creation only)**

---

### Task 1: dot.py — manifest-relative source resolution

**Files:**
- Modify: `dot.py` (add `_config_base_dir`; thread base dir through `_resolve_all_links` → `_resolve_source`; set it in `main()`)
- Test: `tests/test_dotfiles.py` (new class `TestSourceBaseDir`)

**Interfaces:**
- Consumes: existing `_normalize_path(path, globbing, resolve)` (dot.py), `load_config`, `main()`'s `config_path` variable (already computed for the YAML fallback).
- Produces: `_config_base_dir(config, config_path) -> str`; `_resolve_source(source, base_dir=None)`; `_resolve_all_links(links, config)` reads `config["_base_dir"]`. Behavior later tasks rely on: `dot.py --config <abs path> link` works from any cwd.

- [ ] **Step 1: Write the failing tests**

Append to `tests/test_dotfiles.py`:

```python
import json
import subprocess


def _run_dot(config_file, cwd, *link_args):
    """Run dot.py link against a config file from a given cwd."""
    dot_path = os.path.join(os.path.dirname(__file__), "..", "dot.py")
    cmd = [sys.executable, dot_path, "--config", str(config_file), "link", "--yes"]
    cmd.extend(link_args)
    return subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)


class TestSourceBaseDir:
    """dot.py 1.1: relative sources resolve against the manifest, not the cwd"""

    def _setup(self, tmp_path, extra_config=None):
        repo = tmp_path / "repo"
        repo.mkdir()
        (repo / "bashrc").write_text("# payload\n")
        home = tmp_path / "home"
        home.mkdir()
        elsewhere = tmp_path / "elsewhere"
        elsewhere.mkdir()
        config = {"links": {str(home / ".bashrc"): "bashrc"}}
        if extra_config:
            config.update(extra_config)
        config_file = repo / "dotfiles.json"
        config_file.write_text(json.dumps(config))
        return repo, home, elsewhere, config_file

    def test_relative_source_resolves_against_config_dir(self, tmp_path):
        repo, home, elsewhere, config_file = self._setup(tmp_path)

        result = _run_dot(config_file, elsewhere)

        assert result.returncode == 0, result.stdout + result.stderr
        target = home / ".bashrc"
        assert target.is_symlink()
        assert os.path.realpath(str(target)) == str(repo / "bashrc")

    def test_dotfiles_key_overrides_config_dir(self, tmp_path):
        payload = tmp_path / "payload"
        payload.mkdir()
        (payload / "bashrc").write_text("# payload\n")
        home = tmp_path / "home"
        home.mkdir()
        cfg_dir = tmp_path / "cfg"
        cfg_dir.mkdir()
        config_file = cfg_dir / "dotfiles.json"
        config_file.write_text(
            json.dumps(
                {
                    "dotfiles": str(payload),
                    "links": {str(home / ".bashrc"): "bashrc"},
                }
            )
        )

        result = _run_dot(config_file, tmp_path)

        assert result.returncode == 0, result.stdout + result.stderr
        assert os.path.realpath(str(home / ".bashrc")) == str(payload / "bashrc")

    def test_absolute_source_unchanged(self, tmp_path):
        repo, home, elsewhere, config_file = self._setup(tmp_path)
        config_file.write_text(
            json.dumps({"links": {str(home / ".bashrc"): str(repo / "bashrc")}})
        )

        result = _run_dot(config_file, elsewhere)

        assert result.returncode == 0, result.stdout + result.stderr
        assert os.path.realpath(str(home / ".bashrc")) == str(repo / "bashrc")
```

Note: `tests/test_dotfiles.py` already has `import os`, `import sys`, `import pytest`, `import dot`. Add `import json` and `import subprocess` next to them (top of file), not inside the class.

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m pytest tests/test_dotfiles.py::TestSourceBaseDir -v`
Expected: `test_relative_source_resolves_against_config_dir` and `test_dotfiles_key_overrides_config_dir` FAIL (returncode 1, "Bad symlink source"); `test_absolute_source_unchanged` PASSES (absolute paths already work).

- [ ] **Step 3: Implement**

In `dot.py`, add after `load_config` (currently ~line 155):

```python
def _config_base_dir(config, config_path):
    """Directory that relative link sources resolve against.

    Precedence: the manifest's `dotfiles` key, then the config file's
    directory, then the process cwd (no config file at all).
    """
    base = config.get("dotfiles")
    if base:
        return _normalize_path(base, globbing=False)
    if config_path and os.path.isfile(config_path):
        return os.path.dirname(_normalize_path(config_path, globbing=False))
    return os.getcwd()
```

In `_resolve_all_links(links, config)`, at the top add:

```python
    base_dir = config.get("_base_dir") or os.getcwd()
```

and change the `_resolve_source(source)` call to `_resolve_source(source, base_dir)`.

Change `_resolve_source` signature and body:

```python
def _resolve_source(source, base_dir=None):
    expanded = os.path.expandvars(os.path.expanduser(source))
    if base_dir and not os.path.isabs(expanded):
        source = os.path.join(base_dir, expanded)
    abs_sources = _normalize_path(source, globbing=True)
```

(rest of the function unchanged).

In `main()`, right after the `config["home"]` default is set (after the `if not config.get("home"):` block), add:

```python
    # Resolve relative link sources against the manifest, not the cwd
    config["_base_dir"] = _config_base_dir(config, config_path)
```

(`config_path` already exists in `main()` from the YAML-fallback logic.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `python3 -m pytest tests/test_dotfiles.py -v`
Expected: ALL tests pass, including the pre-existing 16.

- [ ] **Step 5: Commit**

```bash
git add dot.py tests/test_dotfiles.py
git commit -m "feat(dot): resolve relative sources against the manifest, not the cwd

The 'dotfiles' config key (previously parsed but ignored) is now the
explicit source root; without it, sources resolve against the config
file's directory. Fixes: 'dot.py --config <path> link' from any cwd."
```

---

### Task 2: dot.py — `--force-relink` flag; warn-and-skip default

**Files:**
- Modify: `dot.py` (link subparser flag; rewrite the differing-source-symlink branch in `cmd_link`)
- Test: `tests/test_dotfiles.py` (new class `TestForceRelink`)

**Interfaces:**
- Consumes: `_run_dot` helper from Task 1's test code.
- Produces: `dot.py ... link --force-relink` repoints differing symlinks with warning `Repointing <target>: was -> <old>, now -> <new>`; without the flag, prints `Symlink <target> exists but points to <old>, not <new>. Skipping (use --force-relink to repoint).` and the run CONTINUES (exit 0). Regular-file targets still abort (exit 1) in both modes. Task 7's bootstrap loop passes this flag.

- [ ] **Step 1: Write the failing tests**

Append to `tests/test_dotfiles.py`:

```python
class TestForceRelink:
    """Differing-source symlink: warn+skip by default, repoint with --force-relink"""

    def _setup(self, tmp_path):
        repo = tmp_path / "repo"
        repo.mkdir()
        (repo / "bashrc").write_text("# new source\n")
        old = tmp_path / "old"
        old.mkdir()
        (old / "bashrc").write_text("# old source\n")
        home = tmp_path / "home"
        home.mkdir()
        target = home / ".bashrc"
        target.symlink_to(old / "bashrc")
        config_file = repo / "dotfiles.json"
        config_file.write_text(json.dumps({"links": {str(target): "bashrc"}}))
        return repo, old, target, config_file

    def test_default_warns_and_skips_and_continues(self, tmp_path):
        repo, old, target, config_file = self._setup(tmp_path)

        result = _run_dot(config_file, tmp_path)

        # Regression: this used to abort the whole run (exit 1)
        assert result.returncode == 0, result.stdout + result.stderr
        assert "Skipping" in result.stdout + result.stderr
        assert os.path.realpath(str(target)) == str(old / "bashrc")

    def test_force_relink_repoints_with_warning(self, tmp_path):
        repo, old, target, config_file = self._setup(tmp_path)

        result = _run_dot(config_file, tmp_path, "--force-relink")

        assert result.returncode == 0, result.stdout + result.stderr
        assert "Repointing" in result.stdout + result.stderr
        assert os.path.realpath(str(target)) == str(repo / "bashrc")

    def test_regular_file_target_still_aborts(self, tmp_path):
        repo, old, target, config_file = self._setup(tmp_path)
        target.unlink()
        target.write_text("# a real file\n")

        for extra in ([], ["--force-relink"]):
            result = _run_dot(config_file, tmp_path, *extra)
            assert result.returncode == 1
            assert target.read_text() == "# a real file\n"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m pytest tests/test_dotfiles.py::TestForceRelink -v`
Expected: first test FAILS (today the run aborts, exit 1); second FAILS (unrecognized argument `--force-relink`); third PASSES already.

- [ ] **Step 3: Implement**

In `main()`, add to the **link** subparser (next to `--no-confirm`/`--yes`):

```python
    link_parser.add_argument(
        "--force-relink",
        action="store_true",
        default=False,
        help="Repoint existing symlinks that point at a different source "
        "(default: warn and skip them)",
    )
```

In `cmd_link`, near the top with the other `args` reads:

```python
    force_relink = args.force_relink
```

Replace the differing-source `else:` branch (the one whose `_errcho("Symlink ... does not point to source ... Not creating")` currently aborts before an unreachable `continue`) with:

```python
            else:
                old_source = _normalize_path(_target, globbing=False, resolve=True)
                if force_relink:
                    print_warning(
                        "Repointing {}: was -> {}, now -> {}".format(
                            _target, old_source, _source
                        )
                    )
                    os.unlink(_target)
                    os.symlink(_source, _target)
                    print_success(
                        "Created symlink: {} --> {}".format(_target, _source)
                    )
                else:
                    print_warning(
                        "Symlink {} exists but points to {}, not {}. "
                        "Skipping (use --force-relink to repoint).".format(
                            _target, old_source, _source
                        )
                    )
                continue
```

Do NOT touch the `if "link" not in target_types:` branch above it — regular-file targets keep aborting via `_errcho`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `python3 -m pytest tests/test_dotfiles.py -v`
Expected: ALL pass.

- [ ] **Step 5: Commit**

```bash
git add dot.py tests/test_dotfiles.py
git commit -m "feat(dot): --force-relink flag; warn-and-skip differing symlinks by default

Previously a symlink pointing at a different source aborted the entire
link run (_errcho exits before the unreachable continue). Now the
default warns and skips; --force-relink repoints with a loud warning."
```

---

### Task 3: dot.py — version 1.1.0, CHANGELOG, README-dot, full gate

**Files:**
- Modify: `dot.py` (VERSION), `CHANGELOG.md`, `README-dot.md`

**Interfaces:**
- Produces: `VERSION = "1.1.0"`; documented behavior for Tasks 1–2.

- [ ] **Step 1: Bump version**

In `dot.py`, change `VERSION = "1.0.0"` to `VERSION = "1.1.0"`.

- [ ] **Step 2: CHANGELOG entry**

Read `CHANGELOG.md` and prepend a new entry above the most recent one, matching its existing heading style:

```markdown
## dot 1.1.0 (2026-07-07)

- Relative link sources now resolve against the manifest: the `dotfiles`
  config key (previously ignored) when present, else the config file's
  directory. Previously they resolved against the process cwd, so
  `dot.py --config <path> link` only worked when run from the manifest's
  directory.
- New `link --force-relink` flag repoints existing symlinks that point at
  a different source, with a loud `Repointing <target>: was -> X, now -> Y`
  warning. Without the flag such symlinks are warned about and skipped;
  previously they aborted the entire run.
- Targets that exist as regular files or directories remain hard refusals.
```

- [ ] **Step 3: README-dot.md updates**

In `README-dot.md`: update the Features list — change the config bullet to mention that relative sources resolve against the config file's directory (or the `dotfiles` key), and add a bullet for `--force-relink`. In the Quick Start config example, add a note line after the JSON block:

```markdown
Relative sources resolve against the `dotfiles` key if set, otherwise
against the directory containing the config file — never against your
shell's current directory.
```

- [ ] **Step 4: Drop the `dotfiles` key from the public manifests**

Remove the `"dotfiles": "~/dotfiles",` line from `dotfiles.json` and the `dotfiles: ~/dotfiles` line from `dotfiles.yaml`. With Task 1's config-dir resolution, the host manifest is now relocatable exactly like an extension's (the key would actually *break* cloning the repo anywhere but `~/dotfiles`, since `~` expands against whatever `$HOME` is). Then verify:

```bash
python3 -c "import json; json.load(open('dotfiles.json'))" && cd /tmp && python3 ~/dotfiles/dot.py --config ~/dotfiles/dotfiles.json link --yes >/dev/null && echo RELOCATABLE_OK && cd ~/dotfiles
```

Expected: `RELOCATABLE_OK` (idempotent re-link from a foreign cwd).

- [ ] **Step 5: Run the full Python gate**

```bash
python3 -m venv /tmp/dotqa 2>/dev/null; /tmp/dotqa/bin/pip install -q -r .github/workflows/requirements-quality.txt PyYAML
/tmp/dotqa/bin/ruff check . && /tmp/dotqa/bin/ruff format --check . && /tmp/dotqa/bin/mypy . --ignore-missing-imports && /tmp/dotqa/bin/pytest tests/ -q
```

Expected: all four green. If `ruff format --check` fails, run `/tmp/dotqa/bin/ruff format dot.py tests/test_dotfiles.py` and re-run the gate.

- [ ] **Step 6: Commit**

```bash
git add dot.py CHANGELOG.md README-dot.md dotfiles.json dotfiles.yaml
git commit -m "chore(dot): release 1.1.0 — manifest-relative sources, --force-relink

Also drop the dotfiles key from the host manifests: with config-dir
resolution the manifest is relocatable, and a ~-based key would break
any clone outside ~/dotfiles."
```

---

### Task 4: `lib/dot-extensions.sh` — discovery, manifest picking, loader, bootstrap

**Files:**
- Create: `lib/dot-extensions.sh`
- Test: `tests/test-extensions.bats`

**Interfaces:**
- Consumes: nothing (self-contained; `debug` and `run_if_changed` are used by `load_dotfiles_modules` but resolved at call time — callers/tests must have them defined).
- Produces (all bash-3.2-safe, ERR-trap-clean, shellcheck-clean):
  - `dot_list_extensions` — prints valid extension dirs (from `${DOTFILES_EXTENSIONS_DIR:-$HOME/.dot/extensions}`) one per line, lexical order; follows symlinks; warns on stderr and skips broken/non-dir entries; prints nothing when the dir is absent/empty. Always returns 0.
  - `dot_extension_manifest <ext_dir>` — prints `<ext>/dotfiles.json` if present, else `<ext>/dotfiles.yaml`, else nothing. Always returns 0.
  - `load_dotfiles_modules <dir> <namespace>` — sources `<dir>/modules/static/[0-9][0-9]-*.sh`, then `<dir>/modules/static/<platform>/[0-9][0-9]-*.sh`, then runs `<dir>/modules/dynamic/*.sh` and `<dir>/modules/dynamic/<platform>/*.sh` through `run_if_changed`. Namespace (may be empty) prefixes dynamic state names as `<namespace>/<module>`; platform is derived as `${OSTYPE%%[0-9]*}`.
  - `dot_bootstrap_extensions <dot_py_path>` — for each extension: runs `<ext>/install.sh` if executable, then links its manifest via `python3 <dot_py_path> --config <manifest> link --yes --force-relink`.

- [ ] **Step 1: Write the failing bats tests**

Create `tests/test-extensions.bats`:

```bash
#!/usr/bin/env bats
# Tests for lib/dot-extensions.sh — the single owner of extension discovery.

setup() {
  TEST_DIR="$(mktemp -d)"
  export DOTFILES_EXTENSIONS_DIR="$TEST_DIR/extensions"
  mkdir -p "$DOTFILES_EXTENSIONS_DIR"
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  # shellcheck source=/dev/null
  source "$REPO_ROOT/lib/dot-extensions.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "dot_list_extensions: absent dir prints nothing, exits 0" {
  export DOTFILES_EXTENSIONS_DIR="$TEST_DIR/nope"
  run dot_list_extensions
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "dot_list_extensions: empty dir prints nothing, exits 0" {
  run dot_list_extensions
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "dot_list_extensions: lexical order" {
  mkdir -p "$DOTFILES_EXTENSIONS_DIR/50-private" "$DOTFILES_EXTENSIONS_DIR/10-work"
  run dot_list_extensions
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "$DOTFILES_EXTENSIONS_DIR/10-work" ]
  [ "${lines[1]}" = "$DOTFILES_EXTENSIONS_DIR/50-private" ]
}

@test "dot_list_extensions: follows dir symlinks" {
  mkdir -p "$TEST_DIR/elsewhere/myext"
  ln -s "$TEST_DIR/elsewhere/myext" "$DOTFILES_EXTENSIONS_DIR/linked"
  run dot_list_extensions
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "$DOTFILES_EXTENSIONS_DIR/linked" ]
}

@test "dot_list_extensions: warns and skips broken symlink" {
  mkdir -p "$DOTFILES_EXTENSIONS_DIR/good"
  ln -s "$TEST_DIR/missing" "$DOTFILES_EXTENSIONS_DIR/broken"
  run dot_list_extensions
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipping"* ]]
  [[ "$output" == *"$DOTFILES_EXTENSIONS_DIR/good"* ]]
  # the broken entry is never printed as a usable extension line
  for line in "${lines[@]}"; do
    [ "$line" != "$DOTFILES_EXTENSIONS_DIR/broken" ]
  done
}

@test "dot_extension_manifest: prefers dotfiles.json" {
  mkdir -p "$DOTFILES_EXTENSIONS_DIR/e"
  touch "$DOTFILES_EXTENSIONS_DIR/e/dotfiles.json" "$DOTFILES_EXTENSIONS_DIR/e/dotfiles.yaml"
  run dot_extension_manifest "$DOTFILES_EXTENSIONS_DIR/e"
  [ "$status" -eq 0 ]
  [ "$output" = "$DOTFILES_EXTENSIONS_DIR/e/dotfiles.json" ]
}

@test "dot_extension_manifest: falls back to dotfiles.yaml" {
  mkdir -p "$DOTFILES_EXTENSIONS_DIR/e"
  touch "$DOTFILES_EXTENSIONS_DIR/e/dotfiles.yaml"
  run dot_extension_manifest "$DOTFILES_EXTENSIONS_DIR/e"
  [ "$status" -eq 0 ]
  [ "$output" = "$DOTFILES_EXTENSIONS_DIR/e/dotfiles.yaml" ]
}

@test "dot_extension_manifest: prints nothing when absent" {
  mkdir -p "$DOTFILES_EXTENSIONS_DIR/e"
  run dot_extension_manifest "$DOTFILES_EXTENSIONS_DIR/e"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "load_dotfiles_modules: host then extensions, lexical order" {
  debug() { :; }
  run_if_changed() { eval "$3"; }
  mkdir -p "$TEST_DIR/host/modules/static" \
    "$DOTFILES_EXTENSIONS_DIR/10-a/modules/static" \
    "$DOTFILES_EXTENSIONS_DIR/20-b/modules/static"
  echo "echo host >> '$TEST_DIR/order.log'" > "$TEST_DIR/host/modules/static/10-mod.sh"
  echo "echo a >> '$TEST_DIR/order.log'" > "$DOTFILES_EXTENSIONS_DIR/10-a/modules/static/10-mod.sh"
  echo "echo b >> '$TEST_DIR/order.log'" > "$DOTFILES_EXTENSIONS_DIR/20-b/modules/static/10-mod.sh"

  load_dotfiles_modules "$TEST_DIR/host" ""
  while IFS= read -r ext; do
    load_dotfiles_modules "$ext" "$(basename "$ext")"
  done < <(dot_list_extensions)

  run cat "$TEST_DIR/order.log"
  [ "${lines[0]}" = "host" ]
  [ "${lines[1]}" = "a" ]
  [ "${lines[2]}" = "b" ]
}

@test "load_dotfiles_modules: dynamic modules get namespaced state names" {
  debug() { :; }
  NAMES_LOG="$TEST_DIR/names.log"
  run_if_changed() { echo "$1" >> "$NAMES_LOG"; }
  mkdir -p "$TEST_DIR/host/modules/dynamic" "$DOTFILES_EXTENSIONS_DIR/priv/modules/dynamic"
  echo "true" > "$TEST_DIR/host/modules/dynamic/setup.sh"
  echo "true" > "$DOTFILES_EXTENSIONS_DIR/priv/modules/dynamic/setup.sh"

  load_dotfiles_modules "$TEST_DIR/host" ""
  load_dotfiles_modules "$DOTFILES_EXTENSIONS_DIR/priv" "priv"

  run cat "$NAMES_LOG"
  [ "${lines[0]}" = "setup" ]
  [ "${lines[1]}" = "priv/setup" ]
}

@test "dot_bootstrap_extensions: runs install.sh and links manifest, idempotent" {
  mkdir -p "$DOTFILES_EXTENSIONS_DIR/e/payload" "$TEST_DIR/home"
  printf '#!/usr/bin/env bash\necho ran >> "%s/install.log"\n' "$TEST_DIR" \
    > "$DOTFILES_EXTENSIONS_DIR/e/install.sh"
  chmod +x "$DOTFILES_EXTENSIONS_DIR/e/install.sh"
  echo "# payload" > "$DOTFILES_EXTENSIONS_DIR/e/payload/rc"
  printf '{"links": {"%s/home/.rc": "payload/rc"}}\n' "$TEST_DIR" \
    > "$DOTFILES_EXTENSIONS_DIR/e/dotfiles.json"

  run dot_bootstrap_extensions "$REPO_ROOT/dot.py"
  [ "$status" -eq 0 ]
  [ -L "$TEST_DIR/home/.rc" ]

  run dot_bootstrap_extensions "$REPO_ROOT/dot.py"
  [ "$status" -eq 0 ]
  run cat "$TEST_DIR/install.log"
  [ "${#lines[@]}" -eq 2 ]
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/test-extensions.bats`
Expected: setup fails on every test — `lib/dot-extensions.sh: No such file or directory`.

- [ ] **Step 3: Implement `lib/dot-extensions.sh`**

```bash
#!/usr/bin/env bash
# dot-extensions: the single owner of extension discovery and loading.
#
# Extensions are repos at ~/.dot/extensions/<name>/ that mirror the host
# dotfiles repo's shape (dotfiles.json, modules/{static,dynamic}[/<platform>],
# install.sh, payload dirs) — every part optional. Loaded after the host, in
# lexical order; last writer wins.
#
# Sourced by BOTH bash_profile (bash 4.3+) and install.sh (may be system
# bash 3.2), so everything here must be bash-3.2-compatible and must not
# produce a nonzero exit status when sourced under set -E / an ERR trap.

# Print valid extension directories in load (lexical) order, one per line.
dot_list_extensions() {
  local ext_parent="${DOTFILES_EXTENSIONS_DIR:-${HOME}/.dot/extensions}"
  local entry
  if [[ ! -d "$ext_parent" ]]; then
    return 0
  fi
  for entry in "$ext_parent"/*; do
    # unmatched glob leaves the literal pattern behind
    if [[ ! -e "$entry" && ! -L "$entry" ]]; then
      continue
    fi
    if [[ -d "$entry" ]]; then # -d follows symlinks
      printf '%s\n' "$entry"
    else
      echo "dot-extensions: skipping non-directory or broken entry: $entry" >&2
    fi
  done
  return 0
}

# Print the manifest path for an extension dir; dotfiles.json preferred.
# Prints nothing when the extension has no manifest.
dot_extension_manifest() {
  local ext="$1"
  if [[ -f "$ext/dotfiles.json" ]]; then
    printf '%s\n' "$ext/dotfiles.json"
  elif [[ -f "$ext/dotfiles.yaml" ]]; then
    printf '%s\n' "$ext/dotfiles.yaml"
  fi
  return 0
}

# Source one dotfiles tree's modules: static, static/<platform>, dynamic,
# dynamic/<platform>. $1 = tree root, $2 = namespace ("" for the host).
# Dynamic modules run through run_if_changed with state name
# "<namespace>/<module>" (bare "<module>" for the host). Requires `debug`
# and `run_if_changed` to be defined by the caller's environment.
load_dotfiles_modules() {
  local dir="$1"
  local namespace="$2"
  local platform="${OSTYPE%%[0-9]*}"
  local module module_name

  for module in "$dir"/modules/static/[0-9][0-9]-*.sh; do
    if [[ -f "$module" ]]; then
      debug "sourcing ${namespace:+${namespace}:}${module##*/}"
      # shellcheck source=/dev/null
      source "$module"
    fi
  done

  if [[ -d "$dir/modules/static/$platform" ]]; then
    for module in "$dir"/modules/static/"$platform"/[0-9][0-9]-*.sh; do
      if [[ -f "$module" ]]; then
        debug "sourcing platform-specific ${namespace:+${namespace}:}${module##*/}"
        # shellcheck source=/dev/null
        source "$module"
      fi
    done
  fi

  for module in "$dir"/modules/dynamic/*.sh; do
    if [[ -f "$module" ]]; then
      module_name="${namespace:+${namespace}/}$(basename "$module" .sh)"
      debug "checking dynamic module: $module_name"
      run_if_changed "$module_name" "$module" "source \"$module\""
    fi
  done

  if [[ -d "$dir/modules/dynamic/$platform" ]]; then
    for module in "$dir"/modules/dynamic/"$platform"/*.sh; do
      if [[ -f "$module" ]]; then
        module_name="${namespace:+${namespace}/}$(basename "$module" .sh)"
        debug "checking platform-specific dynamic module: $module_name"
        run_if_changed "$module_name" "$module" "source \"$module\""
      fi
    done
  fi
  return 0
}

# Bootstrap every extension: run its install.sh, then link its manifest.
# $1 = path to dot.py. --force-relink is the deliberate policy that
# extension links may repoint host-owned symlinks (warned loudly).
dot_bootstrap_extensions() {
  local dot_py="$1"
  local ext ext_name manifest
  while IFS= read -r ext; do
    if [[ -z "$ext" ]]; then
      continue
    fi
    ext_name="$(basename "$ext")"
    echo "Extension: ${ext_name}"
    if [[ -x "$ext/install.sh" ]]; then
      echo "Running ${ext_name}/install.sh..."
      "$ext/install.sh"
    fi
    manifest="$(dot_extension_manifest "$ext")"
    if [[ -n "$manifest" ]]; then
      echo "Linking ${ext_name} manifest..."
      python3 "$dot_py" --config "$manifest" link --yes --force-relink
    fi
  done < <(dot_list_extensions)
  return 0
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bats tests/test-extensions.bats && shellcheck lib/dot-extensions.sh`
Expected: all bats tests PASS; shellcheck clean.

- [ ] **Step 5: Commit**

```bash
git add lib/dot-extensions.sh tests/test-extensions.bats
git commit -m "feat(extensions): lib/dot-extensions.sh — single owner of discovery and loading"
```

---

### Task 5: `run_if_changed` — namespaced state subdirectories

**Files:**
- Modify: `modules/static/00-dotfiles.sh` (the `run_if_changed` function, ~lines 24-64)
- Test: `tests/test-extensions.bats` (one more test)

**Interfaces:**
- Consumes: existing `run_if_changed(name, file, command)`.
- Produces: `run_if_changed "priv/mod" ...` writes `~/.dot/state/priv/mod.hash` (creates the subdirectory). Bare names keep writing `~/.dot/state/<name>.hash` exactly as today — existing hash files stay valid.

- [ ] **Step 1: Write the failing test**

Append to `tests/test-extensions.bats`:

```bash
@test "run_if_changed: namespaced name creates a state subdirectory" {
  debug() { :; }
  # shellcheck source=/dev/null
  source "$REPO_ROOT/modules/static/00-dotfiles.sh"
  export HOME="$TEST_DIR"
  echo "true" > "$TEST_DIR/mod.sh"

  run_if_changed "priv/mod" "$TEST_DIR/mod.sh" "true"

  [ -f "$TEST_DIR/.dot/state/priv/mod.hash" ]
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/test-extensions.bats`
Expected: the new test FAILS (state file written as a flat path fails, or hash file missing — `mkdir -p "$state_dir"` doesn't create `priv/`).

- [ ] **Step 3: Implement**

In `modules/static/00-dotfiles.sh`, inside `run_if_changed`, replace:

```bash
  # Ensure state directory exists
  mkdir -p "$state_dir"
```

with:

```bash
  # Ensure state directory exists ("$name" may contain a namespace
  # subdirectory, e.g. "private/osx_defaults")
  mkdir -p "$(dirname "$hash_file")"
```

and move that line to AFTER `hash_file` is computed (it is computed just above the current `mkdir`; keep the order `state_dir` → `hash_file` → `mkdir`).

- [ ] **Step 4: Run tests to verify they pass**

Run: `bats tests/test-extensions.bats && shellcheck modules/static/00-dotfiles.sh`
Expected: all PASS; shellcheck clean.

- [ ] **Step 5: Commit**

```bash
git add modules/static/00-dotfiles.sh tests/test-extensions.bats
git commit -m "feat(modules): run_if_changed supports namespaced state subdirectories"
```

---

### Task 6: bash_profile — load modules via the shared loader, host then extensions

**Files:**
- Modify: `bash/bash_profile` (replace the four loops at ~lines 84-124 with lib sourcing + loader calls)

**Interfaces:**
- Consumes: `lib/dot-extensions.sh` (`load_dotfiles_modules`, `dot_list_extensions`) from Task 4.
- Produces: identical host module loading as today (order, debug output, ERR-trap regime), plus extension modules loaded after, namespaced.

- [ ] **Step 1: Replace the module-loading section**

In `bash/bash_profile`, the current section between the `[[ ! -d "${DOTFILES_DIR}" ]]` guard and the `# Dynamic modules` block-end (the four loops: static `~87-92`, static/platform `~95-102`, dynamic `~107-113`, dynamic/platform `~116-124`, plus the `platform=` line `~82`) is replaced with:

```bash
# Detect platform is handled inside the loader (strips version numbers:
# darwin24.5.0 -> darwin)

# The extension loader is the single owner of module-loading and
# extension-discovery rules (see docs/superpowers/specs/2026-07-07-dot-extensions-design.md)
source "${DOTFILES_DIR}/lib/dot-extensions.sh"

# Host modules first (empty namespace: state names stay bare)
load_dotfiles_modules "${DOTFILES_DIR}" ""

# Then extensions from ~/.dot/extensions/, lexical order, last one wins
while IFS= read -r _dot_ext; do
  if [[ -n "$_dot_ext" ]]; then
    load_dotfiles_modules "$_dot_ext" "$(basename "$_dot_ext")"
  fi
done < <(dot_list_extensions)
unset _dot_ext
```

Keep everything above (traps, `set -E`, guard) and below (`set +E`, `load_completions`, editor prefs) untouched. Note the standalone `platform=` variable was only used by the removed loops; delete its assignment line if nothing else in bash_profile references it (`grep -n '\$platform' bash/bash_profile` to confirm; `modules/` files derive their own).

- [ ] **Step 2: Verify shell startup, order, and timing**

```bash
shellcheck bash/bash_profile
/opt/homebrew/bin/bash -l -c 'echo "status=$?"'
DOTFILES_DEBUG=1 /opt/homebrew/bin/bash -l -c exit 2>&1 | head -30
time /opt/homebrew/bin/bash -l -c exit
```

Expected: shellcheck clean; `status=0`; debug output shows the same module sequence as before (00-dotfiles … 99-aliases, then darwin modules, then dynamic) with no extension entries yet (`~/.dot/extensions/` doesn't exist); startup time within ~10ms of the pre-change baseline (~90-100ms).

- [ ] **Step 3: Run the full bats suite**

Run: `bats tests/test-validate.bats tests/test-extensions.bats`
Expected: PASS (validate suite exercises real shell startup).

- [ ] **Step 4: Commit**

```bash
git add bash/bash_profile
git commit -m "refactor(shell): load modules via shared loader; extensions after host"
```

---

### Task 7: install.sh — create extensions dir, bootstrap extensions

**Files:**
- Modify: `install.sh` (framework-dirs section + new final section after the login-shell check)

**Interfaces:**
- Consumes: `dot_bootstrap_extensions` from Task 4; `script_dir` variable already defined in install.sh's submodule section.
- Produces: `./install.sh` run N times bootstraps/links every extension idempotently; `~/.dot/extensions/` exists after any run.

- [ ] **Step 1: Extend the framework-dirs section**

In `install.sh`, change:

```bash
mkdir -p "${HOME}/.dot/state"
echo "✓ Created ~/.dot/state/"
```

to:

```bash
mkdir -p "${HOME}/.dot/state" "${HOME}/.dot/extensions"
echo "✓ Created ~/.dot/state/ and ~/.dot/extensions/"
```

- [ ] **Step 2: Add the extensions section**

Immediately before the final `echo ""` / `echo "✅ Installation complete!"` block, add:

```bash
# ============================================================================
# Extensions
# ============================================================================
#
# Extensions are repos cloned (or symlinked) into ~/.dot/extensions/<name>/
# that mirror this repo's shape. See README.md "Extensions" and
# lib/dot-extensions.sh (the single owner of the discovery rules).

echo ""
echo "Checking for extensions..."
# shellcheck source=lib/dot-extensions.sh
source "${script_dir}/lib/dot-extensions.sh"
dot_bootstrap_extensions "${script_dir}/dot.py"
echo "✓ Extensions processed"
```

Note: `script_dir` is set earlier in install.sh (submodule section). If Task ordering ever changes it, define it defensively at the top of this section: `script_dir="${script_dir:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"`.

Also update the header comment block (the `# Prerequisites installed:` list) to mention: `# - extensions (repos under ~/.dot/extensions/) are bootstrapped and linked`.

- [ ] **Step 3: Verify — shellcheck + live idempotent run**

```bash
shellcheck install.sh
./install.sh </dev/null 2>&1 | tail -12
./install.sh </dev/null 2>&1 | tail -12
```

Expected: shellcheck clean; both runs end with `Checking for extensions...` → `✓ Extensions processed` → `✅ Installation complete!`; no errors; no extensions listed yet (dir is empty).

- [ ] **Step 4: Commit**

```bash
git add install.sh
git commit -m "feat(install): bootstrap and link extensions from ~/.dot/extensions/"
```

---

### Task 8: README — Extensions documentation

**Files:**
- Modify: `README.md` (new "Extensions" section after "Configuration")

**Interfaces:**
- Produces: user-facing contract documentation.

- [ ] **Step 1: Add the section**

Insert into `README.md` after the `## Configuration` section:

```markdown
## Extensions

Layer private, work, or experimental config on top of these dotfiles without
forking them. An extension is any repo cloned (or symlinked) into
`~/.dot/extensions/<name>/` that mirrors this repo's shape — every part
optional:

    <extension>/
      dotfiles.json        # symlink manifest (dot.py); omit the "dotfiles"
                           # key so sources resolve against the extension
      modules/static/      # NN-*.sh, sourced every shell, after host modules
      modules/static/<platform>/
      modules/dynamic/     # run-once-on-change, after host
      modules/dynamic/<platform>/
      install.sh           # optional idempotent bootstrap
      <payload>/           # whatever the manifest links to

Setup on a new machine:

    git clone git@github.com:you/dotfiles-private ~/.dot/extensions/private
    cd ~/dotfiles && ./install.sh   # discovers, bootstraps, and links it

Rules:

- Extensions load **after** the host, in lexical order (`10-work` before
  `50-private`) — last writer wins.
- Extension links may repoint host-owned symlinks; the extension loop passes
  `--force-relink`, and every repoint is warned loudly. Prefer layering via
  native includes (git `[include]`, bash source order) over link overrides.
- Modules must be ERR-trap-clean (never end a file with a possibly-false
  bare conditional — use `if` statements): one bad module breaks every
  shell startup, host and extension alike.
- `DOTFILES_EXTENSIONS_DIR` overrides the parent directory. Symlinked
  extension dirs work (clone anywhere, `ln -s` into place).
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: document the extensions contract"
```

---

### Task 9: Migrate Claude config to `stavxyz/dotfiles-private`

**Files:**
- Create (new repo at `~/.dot/extensions/private/`): `dotfiles.json`, `README.md`, `claude/` (moved payload), `modules/static/96-claude-config.sh` (moved + self-locating)
- Modify (public repo): `dotfiles.json`, `dotfiles.yaml` (remove the five `~/.claude/*` entries), delete `claude/` and `modules/static/96-claude-config.sh`

**Interfaces:**
- Consumes: Tasks 1–7 all merged into the working branch (the extension machinery must exist and be linked/loaded).
- Produces: `~/.claude/{settings.json,CLAUDE.md,skills,agents,commands}` symlinks resolving through `~/.dot/extensions/private/claude/`; public repo carries no Claude config.

- [ ] **Step 1: Create the private repo locally**

```bash
mkdir -p ~/.dot/extensions/private/modules/static
cd ~/.dot/extensions/private && git init -b main
cp -R ~/dotfiles/claude ~/.dot/extensions/private/claude
cat > ~/.dot/extensions/private/dotfiles.json <<'EOF'
{
  "links": {
    "~/.claude/settings.json": "claude/settings.json",
    "~/.claude/CLAUDE.md": "claude/CLAUDE.md",
    "~/.claude/skills": "claude/skills",
    "~/.claude/agents": "claude/agents",
    "~/.claude/commands": "claude/commands"
  }
}
EOF
cat > ~/.dot/extensions/private/README.md <<'EOF'
# dotfiles-private

Private extension for [stavxyz/dotfiles](https://github.com/stavxyz/dotfiles).
Cloned at `~/.dot/extensions/private/`; discovered, bootstrapped, and linked
by the public repo's `install.sh`. See the public README's "Extensions"
section for the contract.
EOF
```

Note: no `dotfiles` key in the manifest — relocatable by design.

- [ ] **Step 2: Move the guard module, made self-locating**

Create `~/.dot/extensions/private/modules/static/96-claude-config.sh`:

```bash
#!/usr/bin/env bash
# Module: claude-config
# Description: Claude Code config sync (re-links if the app breaks the symlink)
# Dependencies: none

# Claude Code rewrites ~/.claude/settings.json on /config changes, which
# can replace the extension symlink with a plain file (same failure mode as
# Karabiner). Heal it: sync local changes back to this extension, then
# re-link. Self-locating: this module lives in <ext>/modules/static/.
_claude_ext_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
_claude_settings="${HOME}/.claude/settings.json"
_claude_ext_settings="${_claude_ext_dir}/claude/settings.json"

if [[ -f "$_claude_settings" && ! -L "$_claude_settings" && -f "$_claude_ext_settings" ]]; then
  errcho "claude settings.json is not a symlink"
  _git_status="$(git -C "$_claude_ext_dir" status --short -- claude/settings.json)"
  if [[ -n "$_git_status" ]]; then
    errcho "claude/settings.json has uncommitted changes in dotfiles-private!"
    errcho "Please review and commit those changes first."
    echo "$_git_status"
  else
    echo "Copying local claude settings.json to dotfiles-private..."
    cp -v "$_claude_settings" "$_claude_ext_settings"
    echo "Re-linking claude settings.json to dotfiles-private..."
    rm -f "$_claude_settings"
    ln -s "$_claude_ext_settings" "$_claude_settings"
  fi
  unset _git_status
fi
unset _claude_ext_dir _claude_settings _claude_ext_settings
```

Then: `shellcheck ~/.dot/extensions/private/modules/static/96-claude-config.sh` — expected clean.

- [ ] **Step 3: Remove Claude config from the public repo**

In `~/dotfiles`:

1. Remove these five entries from BOTH `dotfiles.json` and `dotfiles.yaml` `links:` maps: `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, `~/.claude/skills`, `~/.claude/agents`, `~/.claude/commands`.
2. `git rm -r claude/ && git rm modules/static/96-claude-config.sh`
3. Validate the JSON: `python3 -c "import json; json.load(open('dotfiles.json'))"`.

- [ ] **Step 4: Relink through the extension and verify**

```bash
cd ~/dotfiles && ./install.sh </dev/null 2>&1 | tail -8
ls -la ~/.claude/settings.json ~/.claude/CLAUDE.md ~/.claude/skills
python3 -c "import json; print(json.load(open('/Users/stavxyz/.claude/settings.json'))['model'])"
/opt/homebrew/bin/bash -l -c 'echo "startup=$?"' 2>&1 | tail -1
```

Expected: install output shows `Extension: private` and five `Repointing ~/.claude/...` warnings followed by created links; the three `ls` entries point to `~/.dot/extensions/private/claude/...`; settings readable (prints `Fable`); `startup=0` with the guard module now loading from the extension (visible under `DOTFILES_DEBUG=1` as `private:96-claude-config.sh`).

- [ ] **Step 5: Commit both repos and publish the private one**

```bash
cd ~/.dot/extensions/private
git add -A && git commit -m "feat: claude config as a dot extension"
gh repo create stavxyz/dotfiles-private --private --source . --push

cd ~/dotfiles
git add -A
git commit -m "feat!: move claude config to the dotfiles-private extension

The claude/ payload and its guard module now live in the private
extension repo (stavxyz/dotfiles-private, cloned at
~/.dot/extensions/private). Public manifests drop the ~/.claude links."
```

Verify: `gh repo view stavxyz/dotfiles-private --json visibility --jq .visibility` prints `PRIVATE`.

---

### Task 10: End-to-end simulated bootstrap + full gates

**Files:**
- No new source files (verification task; fix anything it surfaces).

**Interfaces:**
- Consumes: everything above.
- Produces: green branch ready for PR.

- [ ] **Step 1: Simulated four-step bootstrap in a scratch HOME**

```bash
SCRATCH="$(mktemp -d)" && export SCRATCH
git clone -q ~/dotfiles "$SCRATCH/dotfiles"
git clone -q ~/.dot/extensions/private "$SCRATCH/ext/private"
mkdir -p "$SCRATCH/home/.dot/extensions"
ln -s "$SCRATCH/ext/private" "$SCRATCH/home/.dot/extensions/private"
# Link host manifest into the scratch home (portable core of steps 2+4;
# install.sh itself curls real installers, so exercise the dot pieces):
HOME="$SCRATCH/home" python3 "$SCRATCH/dotfiles/dot.py" --config "$SCRATCH/dotfiles/dotfiles.json" link --yes
HOME="$SCRATCH/home" bash -c "source '$SCRATCH/dotfiles/lib/dot-extensions.sh' && dot_bootstrap_extensions '$SCRATCH/dotfiles/dot.py'"
ls -la "$SCRATCH/home/.claude/settings.json" "$SCRATCH/home/.bash_profile"
rm -rf "$SCRATCH"
```

Expected: host links point into `$SCRATCH/dotfiles/...`; `~/.claude/settings.json` in the scratch home points into `$SCRATCH/ext/private/claude/settings.json` (proving relocatable manifests + symlinked extension dirs + bootstrap all compose). Note `~/.claude` parent dirs are created by dot.py automatically with `--yes`.

- [ ] **Step 2: Full gates**

```bash
shellcheck install.sh bash/bash_profile lib/dot-extensions.sh modules/static/*.sh modules/static/darwin/*.sh
/tmp/dotqa/bin/ruff check . && /tmp/dotqa/bin/ruff format --check . && /tmp/dotqa/bin/mypy . --ignore-missing-imports && /tmp/dotqa/bin/pytest tests/ -q
bats tests/test-validate.bats tests/test-extensions.bats
time /opt/homebrew/bin/bash -l -c exit
```

Expected: everything green; startup still ~90-100ms.

- [ ] **Step 3: Commit any verification fixes, then hand off for PR**

```bash
git -C ~/dotfiles status --short   # commit any straggler fixes with a targeted message
git -C ~/dotfiles log --oneline main..dot-extensions
```

Expected: a clean series of the Task 1-9 commits. Push and open the PR (see execution handoff — `finishing-a-development-branch` / `gh pr create`); do NOT merge.
