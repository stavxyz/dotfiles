#!/usr/bin/env bash
# Module: claude-config
# Description: Claude Code config sync (re-links if the app breaks the symlink)
# Dependencies: none

# Claude Code rewrites ~/.claude/settings.json on /config changes, which
# can replace the dotfiles symlink with a plain file (same failure mode as
# Karabiner). Heal it: sync local changes back to the repo, then re-link.
_claude_settings="${HOME}/.claude/settings.json"
_claude_dotfiles_settings="${DOTFILES_DIR}/claude/settings.json"

if [[ -f "$_claude_settings" && ! -L "$_claude_settings" && -f "$_claude_dotfiles_settings" ]]; then
  errcho "claude settings.json is not a symlink"
  _git_status="$(git -C "${DOTFILES_DIR}" status --short -- claude/settings.json)"
  if [[ -n "$_git_status" ]]; then
    errcho "claude/settings.json has uncommitted changes in dotfiles!"
    errcho "Please review and commit those changes first."
    echo "$_git_status"
  else
    echo "Copying local claude settings.json to dotfiles repository..."
    cp -v "$_claude_settings" "$_claude_dotfiles_settings"
    echo "Re-linking claude settings.json to dotfiles..."
    rm -f "$_claude_settings"
    ln -s "$_claude_dotfiles_settings" "$_claude_settings"
  fi
  unset _git_status
fi
unset _claude_settings _claude_dotfiles_settings
