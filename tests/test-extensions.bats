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

@test "run_if_changed: namespaced name creates a state subdirectory" {
  debug() { :; }
  # shellcheck source=/dev/null
  source "$REPO_ROOT/modules/static/00-dotfiles.sh"
  export HOME="$TEST_DIR"
  echo "true" > "$TEST_DIR/mod.sh"

  run_if_changed "priv/mod" "$TEST_DIR/mod.sh" "true"

  [ -f "$TEST_DIR/.dot/state/priv/mod.hash" ]
}

@test "dot_bootstrap_extensions: one failing extension does not block later ones" {
  mkdir -p "$DOTFILES_EXTENSIONS_DIR/10-bad" \
    "$DOTFILES_EXTENSIONS_DIR/20-good/payload" "$TEST_DIR/home"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$DOTFILES_EXTENSIONS_DIR/10-bad/install.sh"
  chmod +x "$DOTFILES_EXTENSIONS_DIR/10-bad/install.sh"
  echo "# payload" > "$DOTFILES_EXTENSIONS_DIR/20-good/payload/rc"
  printf '{"links": {"%s/home/.rc2": "payload/rc"}}\n' "$TEST_DIR" \
    > "$DOTFILES_EXTENSIONS_DIR/20-good/dotfiles.json"

  run dot_bootstrap_extensions "$REPO_ROOT/dot.py"
  [ "$status" -eq 0 ]
  [ -L "$TEST_DIR/home/.rc2" ]
  [[ "$output" == *"10-bad/install.sh failed"* ]]
  [[ "$output" == *"failed extension(s): 10-bad"* ]]
}

@test "dot_bootstrap_extensions: failing install.sh skips that extension's own manifest" {
  mkdir -p "$DOTFILES_EXTENSIONS_DIR/bad/payload" "$TEST_DIR/home"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$DOTFILES_EXTENSIONS_DIR/bad/install.sh"
  chmod +x "$DOTFILES_EXTENSIONS_DIR/bad/install.sh"
  echo "# payload" > "$DOTFILES_EXTENSIONS_DIR/bad/payload/rc"
  printf '{"links": {"%s/home/.badrc": "payload/rc"}}\n' "$TEST_DIR" \
    > "$DOTFILES_EXTENSIONS_DIR/bad/dotfiles.json"

  run dot_bootstrap_extensions "$REPO_ROOT/dot.py"
  [ "$status" -eq 0 ]
  [ ! -e "$TEST_DIR/home/.badrc" ]
  [ ! -L "$TEST_DIR/home/.badrc" ]
}
