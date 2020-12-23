#!/usr/bin/env bash

# This should become a script which runs either on new shell
# or on cron for every single file which is managed by the
# dotfiles management program (dot)

# Should this be written in python?
# I should probably re-write everything in golang...

KARABINER_CONFIG_DIR=~/.config/karabiner

# The karabiner app tends to modify or overwrite the symlink
# If either of those occcur, re-link karabiner to dotfiles and notify user

# Check if symlink
if ! [ -L "${KARABINER_CONFIG_DIR}/karabiner.json" ]; then
    # karabiner.json is not a symlink, sad.
    errcho "karabiner.json is not a symlink"
    # this is the part where we should copy karabiner.json to dotfiles
    # but ONLY IF there are no staged or unstaged changes to the
    # karabiner.json in the dotfiles git repository

    # 1) check for staged or unstaged changes
    DOTFILES_GIT_DIFF="$(git -C "${DOTFILES_DIR}" status --short)"
    if [[ DOTFILES_GIT_DIFF =~ "karabiner.json" ]]; then
        errcho "karabiner.json has changed in your dotfiles repository!"
        errcho "Please review and `git commit` those changes."
        errcho "Once committed, any new changes will be synced on the next session invocation."
        echo "${DOTFILES_GIT_DIFF}"
    else
        # karabiner.json was not a symlink @ ~/.config/karabiner/karabiner.json
        # and the git repository version has no staged (or unstaged) changes.
        # Let's copy the currently-in-use file contents to the git repo.
        # karabiner.json is then safe to re-link, which may result in unstaged changes
        # for the git repository version. This is a good thing, and precisely
        # what we're going for.
        echo "Copying local karabiner.json to dotfiles git repository."
        cp -v "${KARABINER_CONFIG_DIR}/karabiner.json" "${DOTFILES_DIR}/karabiner/karabiner.json"
        echo "Linking local karabiner config (target) to karabiner config in git repository (source)."
        ln -i -s "${DOTFILES_DIR}/karabiner/karabiner.json" "${KARABINER_CONFIG_DIR}/karabiner.json"
    fi
fi
