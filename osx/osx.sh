#!/usr/bin/env bash

# disable press-and-hold for additional chars to force key repeat
# seems to be a symptom of setting repeat too fast and I don't need this
defaults write -g ApplePressAndHoldEnabled -bool false

# -globalDomain is equivalent to domain = NSGlobalDomain
# make key repeat fast
defaults write -globalDomain InitialKeyRepeat -int 11
defaults write -globalDomain KeyRepeat -int 1

# echo "globalDomain InitialKeyRepeat: $(defaults read -globalDomain InitialKeyRepeat)"
# echo "globalDomain KeyRepeat: $(defaults read -globalDomain KeyRepeat)"
