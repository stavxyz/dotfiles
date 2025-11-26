#!/usr/bin/env bash
# Module: cache
# Description: Caching system for expensive eval operations
# Dependencies: config.sh

# Cache the result of an eval statement with TTL
# Usage: cache_eval "cache_name" TTL_seconds "command to eval"
# Example: cache_eval "brew_shellenv" 3600 "brew shellenv"
cache_eval() {
    local cache_name="$1"
    local ttl="${2:-3600}"  # 1 hour default
    local eval_cmd="$3"
    local cache_file="${DOTFILES_CACHE_DIR}/${cache_name}.cache"

    # Skip caching if disabled
    if [[ "$DOTFILES_CACHE_EVALS" != "true" ]]; then
        eval "$eval_cmd"
        return
    fi

    # Check if cache exists and is still valid
    if [[ -f "$cache_file" ]]; then
        local cache_age
        if [[ "$OSTYPE" == darwin* ]]; then
            # macOS: use stat -f %m
            cache_age=$(($(date +%s) - $(stat -f %m "$cache_file")))
        else
            # Linux: use stat -c %Y
            cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        fi

        if [[ $cache_age -lt $ttl ]]; then
            # Cache is still valid, source it
            source "$cache_file"
            return
        fi
    fi

    # Cache is invalid or doesn't exist, regenerate
    eval "$eval_cmd" > "$cache_file" 2>/dev/null
    source "$cache_file"
}
