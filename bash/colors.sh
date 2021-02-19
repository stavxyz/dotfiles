#!/usr/bin/env bash

################ BASE16_SHELL #######################
# A shell script to change your shell's default ANSI
# colors but most importantly, colors 17 to 21 of
# your shell's 256 colorspace (if supported by your terminal).
# This script makes it possible to honor the original
# bright colors of your shell (e.g. bright green is still
# green and so on) while providing additional base16 colors
# to applications such as Vim.
# The following sets up autocompletion for base16-shell
BASE16_SHELL=$HOME/.config/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

# https://stackoverflow.com/a/38883860
# setup iterm / vim / tmux / mac menu bar
# requires 'brew install dark-mode'
function theme-switch {
 echo -e "\033]50;SetProfile=$1\a"
 export ITERM_PROFILE=$1
 if [ $1 = "dark" ]; then
    dark-mode on 2> /dev/null # Prevent error message if dark-mode is not installed
    base16_solarized-dark 2> /dev/null # prevent error message if base16-shell is not installed
    vim -c ":set background=dark" +Tmuxline +qall
    if tmux info &> /dev/null; then
        echo "Setting tmux environment to * $ITERM_PROFILE *"
        tmux set-environment ITERM_PROFILE dark
        tmux source-file ~/.tmux/plugins/tmux-colors-solarized/tmuxcolors-dark.conf
    fi
 else
    dark-mode off 2> /dev/null
    base16_solarized-light 2> /dev/null # prevent error message if base16-shell is not installed
    vim -c ":set background=light" +Tmuxline +qall
    if tmux info &> /dev/null; then
        echo "Setting tmux environment to * $ITERM_PROFILE *"
        tmux set-environment ITERM_PROFILE light
        tmux source-file ~/.tmux/plugins/tmux-colors-solarized/tmuxcolors-light.conf
    fi
 fi
}

function go-dark {
  theme-switch dark
}

function let-there-be-light {
  theme-switch light
}
