#!/usr/bin/env bash
# Module: lazy
# Description: Lazy loading system for expensive tools
# Dependencies: config.sh, utils.sh

# Lazy load pyenv if configured
setup_lazy_pyenv() {
    if [[ "$DOTFILES_LAZY_PYENV" == "true" ]] && command_exists pyenv; then
        # Create wrapper function that initializes on first use
        pyenv() {
            unset -f pyenv  # Remove this wrapper
            eval "$(command pyenv init -)"  # Initialize pyenv
            eval "$(pyenv virtualenvwrapper_lazy)" # Initialize virtualenvwrapper
            pyenv "$@"  # Run the actual command
        }
    elif command_exists pyenv; then
        # Eager load
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenvwrapper_lazy)"
    fi
}

# Lazy load direnv if configured
setup_lazy_direnv() {
    if [[ "$DOTFILES_LAZY_DIRENV" == "true" ]] && command_exists direnv; then
        # Create wrapper function that initializes on first use
        direnv() {
            unset -f direnv  # Remove this wrapper
            eval "$(command direnv hook bash)"  # Initialize direnv
            direnv "$@"  # Run the actual command
        }
    elif command_exists direnv; then
        # Eager load
        eval "$(direnv hook bash)"
    fi
}
