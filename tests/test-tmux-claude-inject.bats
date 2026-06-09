#!/usr/bin/env bats
# Test: tmux-claude-resume resurrect post-save injection

setup() {
    export DOTFILES_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export WORK="$(mktemp -d)"
    export TMUX_CLAUDE_RESUME_DIR="$WORK/registry"
    export RESDIR="$WORK/resurrect"
    export FAKE_HOME="$WORK/home"
    mkdir -p "$RESDIR" "$FAKE_HOME/.claude/projects/-tmp-proj"
    export INJECT="$DOTFILES_DIR/tmux-claude-resume/resurrect-inject-claude-resume.sh"

    # Stub tmux: answer the queries the script makes.
    mkdir -p "$WORK/bin"
    cat > "$WORK/bin/tmux" <<EOF
#!/usr/bin/env bash
case "\$*" in
  "show-options -gv @resurrect-dir") echo "$RESDIR" ;;
  "list-panes -a -F #{pane_id}") printf '%%1\n%%2\n' ;;
  "list-panes -a -F"*) printf 'main\t1\t0\t%%1\nmain\t1\t1\t%%2\n' ;;
  *) exit 0 ;;
esac
EOF
    chmod +x "$WORK/bin/tmux"
    export PATH="$WORK/bin:$PATH"

    # Registry: pane %1 -> session WITH a jsonl; pane %2 -> session WITHOUT jsonl.
    source "$DOTFILES_DIR/tmux-claude-resume/registry.sh"
    tcr_record "%1" "live-sess" "/tmp/proj"
    tcr_record "%2" "dead-sess" "/tmp/proj"
    : > "$FAKE_HOME/.claude/projects/-tmp-proj/live-sess.jsonl"   # exists
    # dead-sess.jsonl intentionally absent

    # Save file: pane %1 (session exists), pane %2 (session gone), and a non-claude pane.
    printf 'pane\tmain\t1\t0\t:\t0\t title\t:/tmp/proj\t1\t2.1.168\t:claude --dangerously-skip-permissions -r\n'  > "$RESDIR/last"
    printf 'pane\tmain\t1\t0\t:\t1\t title\t:/tmp/proj\t0\t2.1.168\t:claude --dangerously-skip-permissions -r\n' >> "$RESDIR/last"
    printf 'pane\tmain\t1\t0\t:\t2\t title\t:/tmp/proj\t0\tvim\t:vim\n'                                          >> "$RESDIR/last"
}
teardown() { rm -rf "$WORK"; }

@test "pane with a live session is rewritten to --resume <id>, flags preserved" {
    HOME="$FAKE_HOME" run bash "$INJECT"
    [ "$status" -eq 0 ]
    run grep -c ':claude --dangerously-skip-permissions --resume live-sess$' "$RESDIR/last"
    [ "$output" = "1" ]
}

@test "pane whose session is gone falls back to -r, flags preserved" {
    HOME="$FAKE_HOME" run bash "$INJECT"
    run grep -c ':claude --dangerously-skip-permissions -r$' "$RESDIR/last"
    [ "$output" = "1" ]
}

@test "non-claude pane line is left untouched" {
    HOME="$FAKE_HOME" run bash "$INJECT"
    run grep -c ':vim$' "$RESDIR/last"
    [ "$output" = "1" ]
}

@test "duplicate flags are collapsed (Claude re-adds --dangerously-skip-permissions each launch)" {
    # A pane whose captured command already accumulated the flag (doubled/tripled).
    printf 'pane\tmain\t1\t0\t:\t0\t title\t:/tmp/proj\t1\t2.1.168\t:claude --dangerously-skip-permissions --dangerously-skip-permissions --dangerously-skip-permissions -r\n' > "$RESDIR/last"
    HOME="$FAKE_HOME" run bash "$INJECT"
    [ "$status" -eq 0 ]
    # Exactly one --dangerously-skip-permissions, then --resume <id>.
    run grep -c ':claude --dangerously-skip-permissions --resume live-sess$' "$RESDIR/last"
    [ "$output" = "1" ]
}
