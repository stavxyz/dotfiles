#!/usr/bin/env bash
# Module: keyrepeat
# Description: helper to restore fast key repeat settings
# Dependencies: modules/dynamic/darwin/osx_defaults.sh

# The Keyboard pane in System Settings rewrites KeyRepeat/InitialKeyRepeat
# to slider-quantized values whenever its sliders move, clobbering the
# faster-than-UI values from osx_defaults.sh (the dynamic module is
# hash-gated, so it won't notice). Run this to reapply them.
fix-key-repeat() {
  source "${DOTFILES_DIR}/modules/dynamic/darwin/osx_defaults.sh"
  echo "Key repeat restored (KeyRepeat=1, InitialKeyRepeat=11)."
  echo "Log out and back in for the change to take effect."
}
