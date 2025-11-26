#!/usr/bin/env bash
# Module: osx
# Description: macOS system preferences (keyboard repeat settings)
# Dependencies: bash/source/00-dotfiles.sh (run_if_changed)

# Only apply system preferences if this file has changed since last run
# This prevents unnecessary `defaults write` calls on every shell startup
run_if_changed "osx_prefs" "${DOTFILES_DIR}/osx/osx.sh" '
  # Disable press-and-hold for accent characters (enables key repeat for all keys)
  defaults write -g ApplePressAndHoldEnabled -bool false

  # Set fast key repeat rates
  # InitialKeyRepeat: delay before repeat starts (11 = 165ms)
  # KeyRepeat: speed of repeat (1 = 15ms)
  defaults write -globalDomain InitialKeyRepeat -int 11
  defaults write -globalDomain KeyRepeat -int 1
'
