#!/usr/bin/env bash
# Module: ssh
# Description: SSH agent and key management
# Dependencies: ssh-agent, ssh-add

if ! command -v ssh-agent &>/dev/null; then
    return 0
fi

# SSH agent environment file
SSH_ENV="$HOME/.ssh/agent.env"

# Check if agent is already running
is_agent_running() {
    # Return failure if SSH_AUTH_SOCK is not set
    [[ -n "$SSH_AUTH_SOCK" ]] || return 1

    # Check if ssh-add can communicate with the agent
    # Exit codes: 0=has keys, 1=no keys (but agent running!), 2=cannot connect
    ssh-add -l &>/dev/null
    local rc=$?

    # Return success (0) if agent is running, even with no keys loaded
    [[ $rc -ne 2 ]]
}

# Start ssh-agent and save environment
start_agent() {
    ssh-agent -s > "$SSH_ENV"
    chmod 600 "$SSH_ENV"
    source "$SSH_ENV" > /dev/null
}

# Load existing agent environment if available
if [[ -f "$SSH_ENV" ]]; then
    source "$SSH_ENV" > /dev/null
fi

# Start new agent only if not already running
if ! is_agent_running; then
    start_agent
fi

if ! [[ -d "${HOME}/.ssh" ]]; then
  errcho "${HOME}/.ssh directory does not exist, skipping."
else
  for _key in ~/.ssh/*.pub; do
      # Skip if glob didn't match any files
      [[ -f "$_key" ]] || continue

      # %???? removes '.pub' to target
      # corresponding private key
      _priv="${_key%????}"
      if [ -f "${_priv}" ]; then
        ssh-add -q "${_priv}"
      else
        errcho "corresponding private key ${_priv} does not exist"
      fi
  done
fi
