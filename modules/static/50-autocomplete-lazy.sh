#!/usr/bin/env bash
# Module: autocomplete-lazy
# Description: Asynchronous completion loading system
# Dependencies: config.sh

# Load completions based on configuration
load_completions() {
    local autocomplete_dir="${DOTFILES_DIR}/autocomplete"

    if [[ "$DOTFILES_LAZY_COMPLETIONS" == "true" ]]; then
        # Async loading - load in background after shell is ready
        # This dramatically improves shell startup time
        (
            # Wait a moment for shell to be fully interactive
            sleep 0.1

            # Load all completion files in background
            for f in "$autocomplete_dir"/*.bash; do
                [[ -f "$f" ]] && source "$f" 2>/dev/null
            done
        ) &
        # Don't wait for background job
        disown
    else
        # Eager loading (current behavior) - load synchronously
        for f in "$autocomplete_dir"/*.bash; do
            if [[ -f "$f" ]]; then
                debug "sourcing $f"
                if ! output="$(source "$f" 2>&1)"; then
                    debug "failed to source $f"
                    debug "${output}"
                    break
                fi
                debug "finished sourcing $f"
            fi
        done
    fi
}
