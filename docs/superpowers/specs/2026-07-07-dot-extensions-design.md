# Design: dot extensions — private-repo (and any-repo) overlays for the dotfiles system

**Date:** 2026-07-07
**Status:** Approved
**Motivation:** Claude Code config (settings.json, global CLAUDE.md, skills/) was recently
brought under dotfiles management (`fc3b7b2`), but the dotfiles repo is public. Rather than
open-sourcing personal config — or bolting on a one-off "private repo" special case — this
design makes *extensions* a first-class concept of the dot system. "Private" is merely the
first extension.

## Goal

A four-step fresh-machine bootstrap where private (or work, or experimental) configuration
layers cleanly on top of the public dotfiles:

1. `git clone github.com/stavxyz/dotfiles ~/dotfiles`
2. `cd ~/dotfiles && ./install.sh && ./dot.py link`
3. `git clone git@github.com:stavxyz/dotfiles-private ~/.dot/extensions/private`
4. `./install.sh` again — it discovers the extension, bootstraps and links it. Done.

No new commands to memorize; step 4 is "run the same idempotent script again."

## Concept

"dot" is one conceptual app: the public `stavxyz/dotfiles` repo (the **host**) plus `dot.py`
(the **linker**). The host defines an extension contract; any repo obeying the contract plugs
in. Extensions load *after* the host in lexical order — last writer wins, loudly (consistent
with the existing `NN-` numbered-module precedent).

Separation of mechanism and policy: `dot.py` stays a generic, zero-dependency, single-manifest
symlink linker with **no knowledge of extensions**. The extension concept (discovery, load
order, bootstrap) lives entirely in the host repo's shell code.

## Extension contract (the "shape")

An extension is **self-similar to the host repo**. Every part is optional:

```
<extension>/
  dotfiles.json        # symlink manifest, consumed by dot.py (JSON; YAML also works when PyYAML is present)
  modules/static/      # NN-*.sh, sourced on every shell startup, after host modules
  modules/static/<platform>/   # e.g. darwin/, same $OSTYPE-derived scoping as host
  modules/dynamic/     # run via run_if_changed, after host dynamic modules
  modules/dynamic/<platform>/
  install.sh           # optional idempotent bootstrap, run by host install.sh
  <payload>/           # directories the manifest links to (claude/, git/, ...)
```

Contract rules:

- Manifests should **omit the `dotfiles` key** so relative sources resolve against the
  manifest's own directory (relocatable by default; see dot.py changes).
- Static modules follow the same `[0-9][0-9]-*.sh` naming so ordering is explicit.
- Extensions must not link targets the host owns unless deliberately overriding — an override
  repoints the symlink and warns (see conflict semantics).

## Discovery

- Extensions live at `~/.dot/extensions/<name>/`, discovered by glob (`*/`), loaded in lexical
  order (`10-work` before `50-private` when ordering matters).
- Symlinks are honored: clone a working repo anywhere visible and
  `ln -s ~/src/dotfiles-private ~/.dot/extensions/private`. Broken symlinks: warn and skip.
- `DOTFILES_EXTENSIONS_DIR` overrides the parent directory (default `~/.dot/extensions`).
  No registry file, no env-var lists.
- `~/.dot/` is consolidated as dot's single home directory: `state/` (existing
  run_if_changed hashes), `extensions/` (new), future `cache/` etc. No second top-level
  dot-app directory in `$HOME`.

## dot.py 1.1.0 (generic changes only)

1. **Source resolution.** Relative sources resolve against, in order of precedence:
   1. the manifest's `dotfiles` key (previously parsed-but-ignored; now meaningful), with
      `~` and environment expansion;
   2. the config file's directory.

   Absolute sources are unchanged. This fixes the latent cwd dependence: today
   `dot.py --config ~/dotfiles/dotfiles.json link` run from any other directory fails with
   "Bad symlink source" because relative sources resolve against the process cwd.

2. **Symlink override (last-one-wins, loudly).** When a link target already exists as a
   symlink pointing at a *different* source, repoint it and warn:
   `target: was → old_source, now → new_source`. Rationale: repointing is reversible (both
   sources remain on disk). Targets that are regular files or directories remain hard
   refusals, as today.

3. Housekeeping: version 1.0.0 → 1.1.0, CHANGELOG entry, README-dot.md updates, pytest
   coverage (see Testing).

## Host repo changes

### bash_profile

Extract the four module-loading loops (static, static/platform, dynamic, dynamic/platform)
into a single function:

```
load_dotfiles_modules <dir> <namespace>
```

Call it for `$DOTFILES_DIR` (empty namespace — host state names stay bare, preserving the
existing `~/.dot/state/*.hash` files), then for each discovered extension (namespace =
extension dir name). The namespace prefixes `run_if_changed` state names
(`private:osx_defaults`) so same-named dynamic modules in different extensions cannot collide
in `~/.dot/state/` or with the host. Extension modules run under the same ERR-trap regime as host modules —
the same "must be trap-clean" discipline applies.

Under `DOTFILES_DEBUG`, the loader prints each module it sources with its namespace, making
the layering auditable.

### install.sh

New final section, after the login-shell check: for each extension in lexical order —

1. run `<ext>/install.sh` if present and executable;
2. link the extension's manifest: `./dot.py --config <manifest> link --yes`, where
   `<manifest>` is `<ext>/dotfiles.json` if present, else `<ext>/dotfiles.yaml` (dot.py's
   built-in YAML fallback only applies to the *default* config name, so install.sh picks the
   file explicitly).

Idempotent by construction (each extension's install.sh is required by contract to be
idempotent; dot.py link already is).

### Documentation

README.md gains an "Extensions" section documenting the contract, discovery path, load order,
and override semantics.

## Migration (same change series)

- Create private repo `stavxyz/dotfiles-private`; clone at `~/.dot/extensions/private/`.
- Move from the public repo into it: `claude/` (settings.json, CLAUDE.md, skills/, agents/,
  commands/) and `modules/static/96-claude-config.sh` (the settings.json symlink guard, its
  repo path updated to the extension's location).
- Remove the five `~/.claude/*` link entries from the public manifests (both dotfiles.json
  and dotfiles.yaml); add them to the private manifest.
- Re-link so `~/.claude/*` symlinks point into the extension.
- No history purge of the public repo: the just-committed `claude/` files contain nothing
  sensitive today; the point of this design is what they would have *accumulated*.

## Conflict & error semantics

- Host and extensions overlapping on a link target is a contract violation unless deliberate;
  when it happens, dot.py repoints (symlinks only) and warns. Layering inside tools uses
  their native include mechanisms (git `[include]`, bash source order), not symlink fights.
- Extension missing a manifest or modules dir: that part is skipped silently.
- Broken extension symlink: warn, skip.
- Machine with an empty/absent `~/.dot/extensions/`: zero behavioral change.

## Explicitly out of scope (YAGNI)

- Extension dependency ordering beyond lexical names; a plugin API; dot.py extension
  awareness; multi-profile switching (jean-claude style); private repo CI;
  private-as-submodule (public must stand alone; submodule pinning adds friction for zero
  benefit).

## Testing

- **pytest (dot.py):** relative source with `dotfiles` key; without key (config-dir
  fallback); absolute sources; symlink override warn+repoint; regular-file hard refusal.
- **bats (host):** extension discovery loop (fixture extension in a temp
  `DOTFILES_EXTENSIONS_DIR`); module load order host-then-extension proven via sentinel
  modules; namespaced run_if_changed state; install.sh extension section idempotency.
- **End-to-end:** simulated four-step bootstrap in a temp `HOME`; then the real migration
  verified live — new login shell clean (ERR-trap silent, `$?`=0), `~/.claude/*` resolving
  through `~/.dot/extensions/private/`, Claude Code reading settings through the new links.
