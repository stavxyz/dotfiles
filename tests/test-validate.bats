#!/usr/bin/env bats
# Test: Validation
# Description: Validate functionality after changes

setup() {
    # Dynamically detect dotfiles directory
    export DOTFILES_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export STUB_ROOT="$(mktemp -d)"
    # Loads 41-python.sh and its one dependency into a bare shell.
    export LOAD_PYTHON_MODULE="source '$DOTFILES_DIR/modules/static/10-utils.sh'; source '$DOTFILES_DIR/modules/static/41-python.sh'"
}

teardown() { rm -rf "$STUB_ROOT"; }

@test "bash profile loads without errors" {
    run bash -l -c 'exit'
    [ "$status" -eq 0 ]
}

@test "no syntax errors in bash files" {
    for file in "$DOTFILES_DIR"/bash/*.sh; do
        run bash -n "$file"
        [ "$status" -eq 0 ]
    done
}

@test "utilities module exists and loads" {
    if [ -f "$DOTFILES_DIR/modules/static/10-utils.sh" ]; then
        run bash -c "source $DOTFILES_DIR/modules/static/10-utils.sh && type command_exists"
        [ "$status" -eq 0 ]
    fi
}

@test "config module exists and loads" {
    if [ -f "$DOTFILES_DIR/modules/static/20-config.sh" ]; then
        run bash -c "source $DOTFILES_DIR/modules/static/20-config.sh && echo \$DOTFILES_LAZY_PYENV"
        [ "$status" -eq 0 ]
    fi
}

@test "git commands work" {
    run bash -l -c 'git --version'
    [ "$status" -eq 0 ]
}

@test "vim works" {
    run bash -l -c 'vim --version'
    [ "$status" -eq 0 ]
}

@test "PATH contains expected directories" {
    # Asserts dotfiles PATH setup — meaningless where dotfiles aren't linked
    [ -L ~/.bash_profile ] || skip "dotfiles not linked into HOME"
    run bash -l -c 'echo "$PATH"'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "homebrew" ]]
}

@test "aliases are preserved" {
    run bash -l -c 'alias ll'
    # Should either have ll alias or exit gracefully
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# The completion tests assert on `apex` (autocomplete/apex.bash is the one
# tracked completion file, present on every checkout). Fetched completions
# (git, docker, ...) are covered by the skip-gated end-to-end test below.

@test "completions register at first prompt (deferred/lazy mode)" {
    # Lazy completions load via a one-shot PROMPT_COMMAND hook, which only
    # fires in an interactive shell — drive one through a pipe (the hook
    # runs before the first command executes). Hermetic: sources the module
    # directly so it works on CI runners where dotfiles aren't linked.
    rcfile="$(mktemp)"
    cat > "$rcfile" <<EOF
export DOTFILES_DIR="$DOTFILES_DIR"
export DOTFILES_LAZY_COMPLETIONS=true
debug() { :; }
source "$DOTFILES_DIR/modules/static/50-autocomplete-lazy.sh"
load_completions
EOF
    run bash -c "echo 'complete -p apex' | bash --noprofile --rcfile '$rcfile' -i 2>/dev/null"
    rm -f "$rcfile"
    [ "$status" -eq 0 ]
    [[ "$output" == *apex* ]]
}

@test "completions register at startup (eager mode)" {
    run bash --noprofile --norc -c "export DOTFILES_DIR='$DOTFILES_DIR'; export DOTFILES_LAZY_COMPLETIONS=false; debug() { :; }; source '$DOTFILES_DIR/modules/static/50-autocomplete-lazy.sh'; load_completions; complete -p apex"
    [ "$status" -eq 0 ]
    [[ "$output" == *apex* ]]
}

@test "login shell registers fetched completions end-to-end (lazy)" {
    # Real-machine test: full bash_profile chain + fetched git completion.
    [ -f "$DOTFILES_DIR/autocomplete/git-completion.bash" ] || \
        skip "autocomplete scripts not fetched (run bin/fetch_autocompleters.sh)"
    [ -L ~/.bash_profile ] || skip "dotfiles not linked into HOME"
    run bash -c "echo 'complete -p git' | bash -li 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" == *git* ]]
}

@test "pyenv works if installed" {
    if command -v pyenv &>/dev/null; then
        run bash -l -c 'pyenv --version'
        [ "$status" -eq 0 ]
    else
        skip "pyenv not installed"
    fi
}

@test "direnv works if installed" {
    if command -v direnv &>/dev/null; then
        run bash -l -c 'direnv --version'
        [ "$status" -eq 0 ]
    else
        skip "direnv not installed"
    fi
}

# The pyenv lazy-wrapper tests run against a stub pyenv so they are hermetic
# (CI runners have no pyenv). The stub answers only the subcommands
# 41-python.sh issues while loading; anything else fails loudly, with a message
# that cannot satisfy an assertion on the success markers.
make_stub_pyenv() {
    local root="$1"
    mkdir -p "$root/bin" "$root/plugins/pyenv-virtualenvwrapper"
    cat > "$root/bin/pyenv" <<EOF
#!/usr/bin/env bash
case "\$1" in
    root) echo "$root" ;;
    init) echo 'pyenv() { command pyenv "\$@"; }' ;;
    sh-virtualenvwrapper_lazy) echo 'workon() { echo "workon-stub:\$*"; }' ;;
    --version) echo "pyenv-stub-version" ;;
    *) echo "stub: unexpected subcommand: \$*" >&2; exit 1 ;;
esac
EOF
    chmod +x "$root/bin/pyenv"
}

# Run a bash command with the stub pyenv first on PATH, lazy mode pinned on
# regardless of the developer's own DOTFILES_LAZY_* settings, and FUNCNEST set
# so runaway recursion exits with an error on bash 4.2+ instead of a segfault.
# Usage: stub_bash [VAR=value ...] <command>
stub_bash() {
    local cmd="${*: -1}"
    env HOME="$STUB_ROOT" PATH="$STUB_ROOT/pyenv/bin:$PATH" DOTFILES_LAZY_PYTHON=true FUNCNEST=50 \
        "${@:1:$#-1}" bash --noprofile --norc -c "$cmd"
}

# Emulate Claude Code's shell snapshot: the function table of a shell that has
# loaded the module, minus every underscore-prefixed function.
snapshot_without_underscore_functions() {
    stub_bash "$LOAD_PYTHON_MODULE; for f in \$(declare -F | awk '\$3 !~ /^_/ {print \$3}'); do declare -f \"\$f\"; done"
}

# Assertions below use [ ] rather than [[ ]]: under bash 3.2 bats ignores a
# failing [[ ]] that is not the last line of a test.

@test "pyenv lazy wrappers load in a child shell that inherits PYENV_LAZY_LOADED" {
    # The old loader exported PYENV_LAZY_LOADED=1, so every shell it spawned
    # (tmux pane, nested bash, nvim terminal) started with the flag set, skipped
    # loading, and recursed into its own wrapper until bash segfaulted.
    make_stub_pyenv "$STUB_ROOT/pyenv"
    run stub_bash PYENV_LAZY_LOADED=1 "$LOAD_PYTHON_MODULE; pyenv --version && workon demo"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "pyenv-stub-version" ]
    [ "${lines[1]}" = "workon-stub:demo" ]
}

@test "pyenv lazy wrappers survive a function snapshot without underscore-prefixed helpers" {
    # Claude Code's Bash tool rebuilds its shell from a snapshot of the login
    # shell's functions that omits every function whose name starts with "_",
    # so the public wrappers must not depend on underscore-prefixed helpers.
    make_stub_pyenv "$STUB_ROOT/pyenv"
    snapshot="$(snapshot_without_underscore_functions)"
    run stub_bash "$snapshot
pyenv --version && workon demo"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "pyenv-stub-version" ]
    [ "${lines[1]}" = "workon-stub:demo" ]
}
