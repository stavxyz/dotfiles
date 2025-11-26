#!/usr/bin/env bash
# Module: karabiner_config (dynamic)
# Description: Karabiner-Elements config sync (re-links if app breaks symlink)
# Note: Only runs when karabiner.json changes (hash-based idempotency)

KARABINER_CONFIG_DIR="${HOME}/.config/karabiner"
KARABINER_JSON="${KARABINER_CONFIG_DIR}/karabiner.json"
DOTFILES_KARABINER="${DOTFILES_DIR}/karabiner/karabiner.json"

# Karabiner app sometimes overwrites the symlink - restore it if needed
if [[ ! -L "$KARABINER_JSON" ]]; then
  errcho "karabiner.json is not a symlink"

  # Check if dotfiles version has uncommitted changes
  _git_status="$(git -C "${DOTFILES_DIR}" status --short)"
  if [[ "$_git_status" =~ "karabiner.json" ]]; then
    errcho "karabiner.json has uncommitted changes in dotfiles!"
    errcho "Please review and commit those changes first."
    echo "$_git_status"
  else
    # Safe to sync: copy current config to dotfiles, then re-link
    echo "Copying local karabiner.json to dotfiles repository..."
    cp -v "$KARABINER_JSON" "$DOTFILES_KARABINER" || errcho "Failed to copy config"
    echo "Re-linking karabiner config to dotfiles..."
    rm -f "$KARABINER_JSON" || errcho "Failed to remove original"
    ln -s "$DOTFILES_KARABINER" "$KARABINER_JSON" || errcho "Failed to create symlink"
  fi
fi
