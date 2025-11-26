#!/usr/bin/env bash
# Module: colors
# Description: Color themes and switching for shell, vim, tmux, and iTerm2
# Dependencies: base16-shell, dark-mode, nvim, tmux (optional)

# ============================================================================
# Base16 Shell Setup
# ============================================================================

# Base16 provides consistent color schemes across terminal, vim, and tmux
# Adds colors 17-21 to the 256 colorspace while preserving bright colors
BASE16_SHELL="$HOME/.config/base16-shell/"
[[ -n "$PS1" && -s "$BASE16_SHELL/profile_helper.sh" ]] && eval "$($BASE16_SHELL/profile_helper.sh)"

# ============================================================================
# Theme Switching
# ============================================================================

# Unified theme switching for iTerm2, macOS, base16, vim, and tmux
# Requires: dark-mode (brew install dark-mode)
theme-switch() {
  local theme="$1"

  # Set iTerm2 profile
  echo -e "\033]50;SetProfile=$theme\a"

  if [[ "$theme" == "dark" ]]; then
    # macOS dark mode
    dark-mode on 2>/dev/null

    # Shell colors (base16 or iTerm2 fallback)
    base16_solarized-dark 2>/dev/null || it2setcolor preset 'Solarized Dark'

    # Vim/Tmux line
    nvim -c ":set background=dark" +Tmuxline +qall 2>/dev/null

    # Tmux colors
    if tmux info &>/dev/null; then
      echo "Setting tmux environment to dark"
      tmux set-environment ITERM_PROFILE dark
      tmux source-file ~/.tmux/plugins/tmux-colors-solarized/tmuxcolors-dark.conf 2>/dev/null
    fi
  else
    # macOS light mode
    dark-mode off 2>/dev/null

    # Shell colors (base16 or iTerm2 fallback)
    base16_solarized-light 2>/dev/null || it2setcolor preset 'Solarized Light'

    # Vim/Tmux line
    nvim -c ":set background=light" +Tmuxline +qall 2>/dev/null

    # Tmux colors
    if tmux info &>/dev/null; then
      echo "Setting tmux environment to light"
      tmux set-environment ITERM_PROFILE light
      tmux source-file ~/.tmux/plugins/tmux-colors-solarized/tmuxcolors-light.conf 2>/dev/null
    fi
  fi
}

# Convenience aliases
go-dark() { theme-switch dark; }
let-there-be-light() { theme-switch light; }
