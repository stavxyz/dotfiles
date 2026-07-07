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
[[ -n "$PS1" && -s "$BASE16_SHELL/profile_helper.sh" ]] && eval "$("$BASE16_SHELL"/profile_helper.sh)"

# ============================================================================
# Theme Switching
# ============================================================================

# Unified theme switching for the terminal, macOS, base16, vim, and tmux.
# Terminal-specific integrations are opt-in by detection ($TERM_PROGRAM);
# everything else works in any terminal.
theme-switch() {
  local theme="$1"
  if [[ "$theme" != "dark" && "$theme" != "light" ]]; then
    echo "usage: theme-switch <dark|light>" >&2
    return 1
  fi

  # Canonical theme variable; tmux.conf and vim honor it in any terminal
  export DOTFILES_THEME="$theme"

  # --- terminal emulator colors: per-terminal adapters ---
  case "${TERM_PROGRAM:-}" in
    iTerm.app)
      # Switch to the iTerm2 profile named after the theme
      echo -e "\033]50;SetProfile=$theme\a"
      ;;
    Apple_Terminal)
      # Terminal.app ignores OSC palette escapes; switch its profile via
      # AppleScript instead. Profile names are overridable via
      # DOTFILES_TERMINAL_PROFILE_DARK / DOTFILES_TERMINAL_PROFILE_LIGHT.
      local profile
      if [[ "$theme" == "dark" ]]; then
        profile="${DOTFILES_TERMINAL_PROFILE_DARK:-Clear Dark}"
      else
        profile="${DOTFILES_TERMINAL_PROFILE_LIGHT:-Clear Light}"
      fi
      if ! osascript >/dev/null 2>&1 <<APPLESCRIPT
tell application "Terminal"
  set default settings to settings set "$profile"
  repeat with w in windows
    try
      set current settings of tabs of w to settings set "$profile"
    end try
  end repeat
end tell
APPLESCRIPT
      then
        echo "theme-switch: could not switch Terminal.app to profile '$profile'" >&2
      fi
      ;;
  esac

  # --- macOS system appearance (osascript first, dark-mode CLI fallback) ---
  if [[ "$OSTYPE" == darwin* ]]; then
    local dark_mode="false"
    [[ "$theme" == "dark" ]] && dark_mode="true"
    if ! osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $dark_mode" >/dev/null 2>&1; then
      if [[ "$theme" == "dark" ]]; then dark-mode on 2>/dev/null; else dark-mode off 2>/dev/null; fi
    fi
  fi

  # --- shell colors (base16; works in any OSC-4-capable terminal) ---
  "base16_solarized-${theme}" 2>/dev/null || true

  # --- vim background + airline/tmuxline ---
  nvim -c ":set background=${theme}" +Tmuxline +qall 2>/dev/null

  # --- tmux colors ---
  if tmux info &>/dev/null; then
    echo "Setting tmux environment to ${theme}"
    tmux set-environment DOTFILES_THEME "$theme"
    tmux set-environment ITERM_PROFILE "$theme" # legacy consumers
    tmux source-file "${HOME}/.tmux/plugins/tmux-colors-solarized/tmuxcolors-${theme}.conf" 2>/dev/null
  fi
}

# Convenience aliases
go-dark() { theme-switch dark; }
let-there-be-light() { theme-switch light; }
