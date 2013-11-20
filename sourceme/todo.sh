#!/bin/bash
#
# Creates something for me to do.
#
# Inspired by https://github.com/holman/dotfiles/blob/master/bin/todo
#
# All `todo` does is put a file on my Desktop with the filename given. That's
# it. I aggressively prune my desktop of old tasks and keep one or two on there
# at a time. Once I've finished a todo, I just delete the file. That's it.
#
# Millions of dollars later and `touch` wins.

# Run our new web 2.0 todo list application and raise millions of VC dollars.

todo() { touch ~/Desktop/"$*"; }

