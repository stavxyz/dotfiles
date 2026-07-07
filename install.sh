#!/usr/bin/env bash
#
# Dotfiles Installation Script
#
# Usage: ./install.sh
#
# This script installs prerequisites for the dotfiles system.
# It is idempotent and can be run multiple times safely.
#
# Prerequisites installed:
# - vim-plug (Vim plugin manager)
# - TPM (tmux plugin manager)
# - pyenv (Python version manager via pyenv-installer)
# - pyenv-virtualenvwrapper (Python virtual environment tools)
#
# Also checks that the login shell is a modern bash (the dotfiles are
# bash-centric) and offers to switch it — always asks first.
#
# Note: This script only installs missing components. It does not update
# existing installations. Use the appropriate update method for each tool:
#   - vim-plug: Run :PlugUpdate in Vim
#   - TPM: Run `prefix + U` inside tmux to update plugins
#   - pyenv: Run `pyenv update` (if installed via pyenv-installer) or `brew upgrade pyenv`
#   - pyenv-virtualenvwrapper: `cd $(pyenv root)/plugins/pyenv-virtualenvwrapper && git pull`
#
# After running, execute: ./dot.py link

set -euo pipefail

echo "Installing dotfiles prerequisites..."

# ============================================================================
# Dotfiles Framework Directories
# ============================================================================

echo "Creating dotfiles framework directories..."
mkdir -p "${HOME}/.dot/state"
echo "✓ Created ~/.dot/state/"

# ============================================================================
# Git Submodules (base16-shell etc.)
# ============================================================================

# A fresh clone has empty submodule dirs, which breaks base16 theming and
# aborts `dot.py link`. Idempotent: a no-op when already initialized.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${script_dir}/.gitmodules" ]] && command -v git &>/dev/null; then
    echo "Initializing git submodules..."
    git -C "$script_dir" submodule update --init --recursive
    echo "✓ Submodules initialized"
fi

# ============================================================================
# Vim Plugin Manager
# ============================================================================

if [[ -f ~/.vim/autoload/plug.vim ]]; then
    echo "✓ vim-plug already installed"
else
    echo "Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Neovim shares the vimrc (linked to ~/.config/nvim/init.vim) but looks for
# autoload scripts under its own data dir, not ~/.vim
if [[ -f ~/.local/share/nvim/site/autoload/plug.vim ]]; then
    echo "✓ vim-plug (neovim) already installed"
else
    echo "Installing vim-plug for neovim..."
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# ============================================================================
# TMUX Plugin Manager (TPM)
# ============================================================================

if [[ -d ~/.tmux/plugins/tpm ]]; then
    echo "✓ TPM (tmux plugin manager) already installed"
else
    echo "Installing TPM (tmux plugin manager)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# ============================================================================
# Python Environment Manager (pyenv)
# ============================================================================

# Check if pyenv is already installed. Look in ~/.pyenv/bin too: pyenv is
# only on PATH once the dotfiles are loaded, and this script must stay
# idempotent when run from a stock shell.
if [[ -d ~/.pyenv ]] && { command -v pyenv &>/dev/null || [[ -x "${HOME}/.pyenv/bin/pyenv" ]]; }; then
    echo "✓ pyenv already installed"
    export PATH="${HOME}/.pyenv/bin:$PATH"
    # Detect shell type for cross-shell compatibility
    shell_type="$(basename "${SHELL:-bash}")"
    eval "$(pyenv init - "$shell_type")" || { echo "Error: pyenv init failed."; exit 1; }
else
    # pyenv not found or incomplete - install via pyenv-installer
    echo "Installing pyenv via pyenv-installer..."
    curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

    export PATH="${HOME}/.pyenv/bin:$PATH"
    if command -v pyenv &>/dev/null; then
        # Detect shell type for cross-shell compatibility
        shell_type="$(basename "${SHELL:-bash}")"
        eval "$(pyenv init - "$shell_type")" || { echo "Error: pyenv init failed."; exit 1; }
    else
        echo "Error: pyenv installation failed"
        exit 1
    fi
fi

# ============================================================================
# Python Virtual Environment Tools
# ============================================================================

VENVWRAPPER_DIR="$(pyenv root)/plugins/pyenv-virtualenvwrapper"
if [[ -d "$VENVWRAPPER_DIR" ]]; then
    echo "✓ pyenv-virtualenvwrapper already installed"
else
    echo "Installing pyenv-virtualenvwrapper..."
    git clone https://github.com/pyenv/pyenv-virtualenvwrapper.git "$VENVWRAPPER_DIR"
fi

# ============================================================================
# Login Shell (optional)
# ============================================================================
#
# The dotfiles are bash-centric (~/.bash_profile, ~/.bashrc, modules/) and
# only load when bash is the login shell. macOS defaults to zsh and ships
# bash 3.2; the config needs bash 4.3+ (macOS: bash 5+ via `brew install
# bash`). Detect the situation and offer to switch. Never switches without
# asking; prints the manual commands when run non-interactively.

echo ""
echo "Checking login shell..."

# Require bash >= 4.3
_bash_version_ok() {
    local major minor
    # shellcheck disable=SC2016  # expand in the candidate bash, not here
    major="$("$1" -c 'echo "${BASH_VERSINFO[0]}"' 2>/dev/null)" || return 1
    # shellcheck disable=SC2016  # expand in the candidate bash, not here
    minor="$("$1" -c 'echo "${BASH_VERSINFO[1]}"' 2>/dev/null)" || return 1
    [[ "$major" -gt 4 ]] || [[ "$major" -eq 4 && "$minor" -ge 3 ]]
}

current_user="${USER:-$(id -un)}"
if [[ "$(uname -s)" == "Darwin" ]]; then
    login_shell="$(dscl . -read "/Users/${current_user}" UserShell 2>/dev/null | awk '{print $2}')"
else
    login_shell="$(getent passwd "${current_user}" 2>/dev/null | cut -d: -f7)"
fi
login_shell="${login_shell:-${SHELL:-unknown}}"

brew_prefix="$(brew --prefix 2>/dev/null || true)"
preferred_bash=""
for candidate in "${brew_prefix:+${brew_prefix}/bin/bash}" /opt/homebrew/bin/bash /usr/local/bin/bash /usr/bin/bash /bin/bash; do
    [[ -n "$candidate" && -x "$candidate" ]] || continue
    if _bash_version_ok "$candidate"; then
        preferred_bash="$candidate"
        break
    fi
done

if [[ -z "$preferred_bash" ]]; then
    echo "⚠️  No bash >= 4.3 found; the dotfiles will not load without one."
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "   Install one with: brew install bash  (then re-run ./install.sh)"
    fi
elif [[ "$login_shell" == "$preferred_bash" ]]; then
    echo "✓ Login shell is already ${preferred_bash}"
else
    echo "Your login shell is ${login_shell}, but these dotfiles only load under bash."
    echo "Suitable bash found: ${preferred_bash}"
    change_shell="no"
    if [[ -t 0 ]]; then
        read -r -p "Change your login shell to ${preferred_bash}? [y/N] " reply
        [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]] && change_shell="yes"
    else
        echo "(non-interactive run — not changing your shell)"
    fi
    if [[ "$change_shell" == "yes" ]]; then
        # chsh only accepts shells listed in /etc/shells
        if ! grep -qx "$preferred_bash" /etc/shells; then
            echo "Adding ${preferred_bash} to /etc/shells (requires sudo)..."
            echo "$preferred_bash" | sudo tee -a /etc/shells >/dev/null
        fi
        if chsh -s "$preferred_bash"; then
            echo "✓ Login shell changed to ${preferred_bash} (takes effect in new terminals)"
        else
            echo "⚠️  chsh failed; login shell unchanged."
            change_shell="no"
        fi
    fi
    if [[ "$change_shell" == "no" ]]; then
        echo "To change it later:"
        echo "  grep -qx '${preferred_bash}' /etc/shells || echo '${preferred_bash}' | sudo tee -a /etc/shells"
        echo "  chsh -s '${preferred_bash}'"
    fi
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (to load pyenv)"
echo "  2. Run: ./dot.py link"
echo "  3. Inside tmux, press 'prefix + I' to install tmux plugins"
echo ""
