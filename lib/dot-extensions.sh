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

# load_dotfiles_modules depends on two hooks from the caller's environment:
# `debug` (bash_profile) and `run_if_changed` (host 00-dotfiles.sh, defined
# during the static phase of the host's own load). Declare the cheap one's
# fallback here; the load-bearing one is checked fail-loud at the point it
# is first needed (see load_dotfiles_modules).
if ! declare -f debug >/dev/null; then
  debug() { :; }
fi

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

  # The dynamic phase requires run_if_changed. In normal operation the host's
  # static phase (00-dotfiles.sh, sourced just above) has defined it by now;
  # fail loudly rather than half-load if that contract is broken.
  if ! declare -f run_if_changed >/dev/null; then
    echo "load_dotfiles_modules: run_if_changed is not defined; skipping dynamic modules in $dir" >&2
    return 1
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
# Extensions are independent layers: one extension's failure is reported
# loudly but never blocks the others (or the caller — always returns 0,
# so install.sh's set -e completes the rest of the bootstrap).
dot_bootstrap_extensions() {
  local dot_py="$1"
  local ext ext_name manifest failed_exts=""
  while IFS= read -r ext; do
    if [[ -z "$ext" ]]; then
      continue
    fi
    ext_name="$(basename "$ext")"
    echo "Extension: ${ext_name}"
    if [[ -x "$ext/install.sh" ]]; then
      echo "Running ${ext_name}/install.sh..."
      if ! "$ext/install.sh"; then
        echo "dot-extensions: ${ext_name}/install.sh failed; skipping its manifest" >&2
        failed_exts="${failed_exts} ${ext_name}"
        continue
      fi
    fi
    manifest="$(dot_extension_manifest "$ext")"
    if [[ -n "$manifest" ]]; then
      echo "Linking ${ext_name} manifest..."
      if ! python3 "$dot_py" --config "$manifest" link --yes --force-relink; then
        echo "dot-extensions: linking ${ext_name} manifest failed" >&2
        failed_exts="${failed_exts} ${ext_name}"
      fi
    fi
  done < <(dot_list_extensions)
  if [[ -n "$failed_exts" ]]; then
    echo "dot-extensions: WARNING — failed extension(s):${failed_exts}" >&2
  fi
  return 0
}
