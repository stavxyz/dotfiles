#!/usr/bin/env bash

errcho() {
  >&2 echo $@
}

DOTFILES_GIT_DIR=$(git rev-parse --show-toplevel || true)
DOTFILES_DIR=${DOTFILES_GIT_DIR:-${DOTFILES_DIR}}

if [ ! -d "${DOTFILES_DIR}" ]; then
  errcho 'dotfiles directory not found (not sure where to put autocomplete scripts)'
else
  curl -L https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash \
    -o $DOTFILES_DIR/autocomplete/git-completion.bash

  echo -e "\n *** Fetching docker autocomplete script. ***"
  curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker \
    -o $DOTFILES_DIR/autocomplete/docker-completion.bash

  echo -e "\n *** Fetching docker-compose autocomplete script. ***"
  curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose \
    -o $DOTFILES_DIR/autocomplete/docker-compose-completion.bash

  echo -e "\n *** Fetching virtualenvwrapper autocomplete script. ***"
  curl -L https://bitbucket.org/virtualenvwrapper/virtualenvwrapper/raw/master/virtualenvwrapper.sh \
    -o $DOTFILES_DIR/autocomplete/virtualenvwrapper-completion.bash

  if [[ $OSTYPE == *"darwin"* ]]; then
    echo -e "\n *** Fetching homebrew autocomplete script. ***"
    curl -L https://raw.githubusercontent.com/Homebrew/brew/master/completions/bash/brew \
      -o $DOTFILES_DIR/autocomplete/homebrew-completion.bash
  fi

fi
