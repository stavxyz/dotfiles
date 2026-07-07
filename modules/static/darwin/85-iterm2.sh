#!/usr/bin/env bash
# Module: iterm2
# Description: iTerm2 shell integration
# Dependencies: none

# Load iTerm2 shell integration if available
if [[ -f "${HOME}/.iterm2_shell_integration.bash" ]]; then
  source "${HOME}/.iterm2_shell_integration.bash"
fi
