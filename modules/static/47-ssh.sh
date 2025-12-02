#!/usr/bin/env bash
# Module: ssh
# Description: SSH agent and key management with optional lazy loading
# Dependencies: utils.sh

setup_ssh() {
    if ! command_exists ssh-agent || ! command_exists ssh-add; then
        return 0
    fi

    # SSH agent environment file (local variable, not exported)
    # Note: Renamed from SSH_ENV to ssh_env for better conventions
    # (uppercase is reserved for exported environment variables)
    local ssh_env="$HOME/.ssh/agent.env"

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
        # Use umask to set permissions atomically (prevents race condition)
        (
            umask 077
            ssh-agent -s > "$ssh_env"
        )
        source "$ssh_env" > /dev/null
    }

    # Load existing agent environment if available
    [[ -f "$ssh_env" ]] && source "$ssh_env" > /dev/null

    # Start new agent only if not already running
    if ! is_agent_running; then
        start_agent
    fi

    # Load SSH keys
    if [[ -d "${HOME}/.ssh" ]]; then
        for _key in "${HOME}"/.ssh/*.pub; do
            # Skip if glob didn't match any files
            [[ -f "$_key" ]] || continue

            # Remove '.pub' to target corresponding private key
            local _priv_key="${_key%.pub}"
            if [[ -f "${_priv_key}" ]]; then
                ssh-add -q "${_priv_key}"
            else
                errcho "Corresponding private key ${_priv_key} does not exist"
            fi
        done
    fi
}

# SSH usually needed immediately - lazy loading optional
if [[ "$DOTFILES_LAZY_SSH" == "true" ]]; then
    ssh() {
        unset -f ssh
        setup_ssh
        command ssh "$@"
    }
else
    setup_ssh
fi
