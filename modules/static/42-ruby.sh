#!/usr/bin/env bash
# Module: ruby
# Description: Ruby/chruby configuration with optional lazy loading
# Dependencies: utils.sh, homebrew.sh

if ! command_exists brew; then
    return 0
fi

setup_ruby() {
    # Detect HOMEBREW_PREFIX (set by 15-homebrew.sh)
    if [[ -z "$HOMEBREW_PREFIX" ]]; then
        if is_apple_silicon; then
            HOMEBREW_PREFIX="/opt/homebrew"
        else
            HOMEBREW_PREFIX="/usr/local"
        fi
    fi

    local chruby_path="${HOMEBREW_PREFIX}/opt/chruby"
    if [[ ! -d "$chruby_path" ]]; then
        chruby_path="$(brew --prefix chruby 2>/dev/null)" || return 0
    fi
    [[ -z "$chruby_path" ]] && return 0

    [[ -f "${chruby_path}/share/chruby/chruby.sh" ]] && \
        source "${chruby_path}/share/chruby/chruby.sh"
    [[ -f "${chruby_path}/share/chruby/auto.sh" ]] && \
        source "${chruby_path}/share/chruby/auto.sh"

    return 0
}

# Ruby lazy loading optional (chruby is fast)
if [[ "$DOTFILES_LAZY_RUBY" == "true" ]]; then
    chruby() {
        unset -f chruby
        setup_ruby
        chruby "$@"
    }
else
    setup_ruby
fi
