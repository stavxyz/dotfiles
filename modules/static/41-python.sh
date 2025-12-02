#!/usr/bin/env bash
# Module: python
# Description: Python/pyenv configuration with lazy loading
# Dependencies: config.sh, utils.sh

export PYENV_ROOT="$HOME/.pyenv"
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
export WORKON_HOME="$HOME/.virtualenvs"

[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"

setup_python() {
    local lazy_mode="${DOTFILES_LAZY_PYTHON:-${DOTFILES_LAZY_PYENV:-true}}"

    # Load raw virtualenvwrapper (standalone, not pyenv plugin)
    # Try to find virtualenvwrapper scripts in common locations
    local vw_lazy_script=""
    local vw_script=""

    if command_exists virtualenvwrapper_lazy.sh; then
        vw_lazy_script="$(command -v virtualenvwrapper_lazy.sh)"
        vw_script="$(command -v virtualenvwrapper.sh)"
    elif [[ -f "/usr/local/bin/virtualenvwrapper_lazy.sh" ]]; then
        vw_lazy_script="/usr/local/bin/virtualenvwrapper_lazy.sh"
        vw_script="/usr/local/bin/virtualenvwrapper.sh"
    elif command_exists pyenv; then
        local pyenv_version pyenv_bin
        pyenv_version="$(pyenv version-name 2>/dev/null)"
        if [[ -n "$pyenv_version" ]]; then
            pyenv_bin="$(pyenv root)/versions/${pyenv_version}/bin"
            if [[ -f "${pyenv_bin}/virtualenvwrapper_lazy.sh" ]]; then
                vw_lazy_script="${pyenv_bin}/virtualenvwrapper_lazy.sh"
                vw_script="${pyenv_bin}/virtualenvwrapper.sh"
                export VIRTUALENVWRAPPER_PYTHON="${pyenv_bin}/python"
            fi
        fi
    fi

    if [[ -n "$vw_lazy_script" && -f "$vw_lazy_script" && -f "$vw_script" ]]; then
        export VIRTUALENVWRAPPER_SCRIPT="$vw_script"
        # shellcheck source=/dev/null
        source "$vw_lazy_script"
    fi

    # Setup pyenv (lazy or eager)
    if [[ "$lazy_mode" == "true" ]] && command_exists pyenv; then
        eval "$(command pyenv init - --path)"
        pyenv() {
            unset -f pyenv
            eval "$(command pyenv init -)"
            pyenv "$@"
        }
    elif command_exists pyenv; then
        eval "$(command pyenv init -)"
    fi
}

setup_python
