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
  # Karabiner's virtual keyboard reads these values only when it is
  # created, so kick its user service to recreate it — this makes the
  # change take effect immediately, no logout needed.
  local karabiner_service
  karabiner_service="gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server"
  if launchctl print "$karabiner_service" &>/dev/null; then
    launchctl kickstart -k "$karabiner_service"
    echo "Karabiner virtual keyboard recreated; settings are live now."
  else
    echo "Log out and back in for the change to take effect."
  fi
}
