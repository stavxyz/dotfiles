#!/usr/bin/env bash


_cmd_exists () {
  if ! type "$*" &> /dev/null; then
    errcho "$* command not installed"
    return 1
  fi
}

if _cmd_exists chef; then
  export CHEF_LICENSE='accept'
  _chefgembin="$(chef exec 'echo $GEM_HOME')/bin"
  export PATH=$PATH:"${_chefgembin}"
  alias chefirb='/opt/chef-workstation/embedded/bin/irb'
  _chef_setup="$(chef shell-init bash)"
  eval "${_chef_setup}"
else
  echo "chef-workstation not installed"
fi
