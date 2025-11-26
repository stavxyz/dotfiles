#!/usr/bin/env bash
# Module: osx
# Description: macOS system preferences (keyboard repeat settings)
# Dependencies: none

# Disable press-and-hold for accent characters (enables key repeat for all keys)
defaults write -g ApplePressAndHoldEnabled -bool false

# Set fast key repeat rates
# InitialKeyRepeat: delay before repeat starts (11 = 165ms)
# KeyRepeat: speed of repeat (1 = 15ms)
defaults write -globalDomain InitialKeyRepeat -int 11
defaults write -globalDomain KeyRepeat -int 1
