#!/bin/bash

# fetch autocomplete scripts
echo -e "\n *** Fetching git autocomplete script. ***"
curl -L https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash \
  -o ~/.autocomplete/git-completion.bash

echo -e "\n *** Fetching mercurial autocomplete script. ***"
curl -L https://selenic.com/hg/raw-file/tip/contrib/bash_completion \
  -o ~/.autocomplete/hg-completion.bash

echo -e "\n *** Fetching docker autocomplete script. ***"
curl -L https://raw.githubusercontent.com/docker/docker/master/contrib/completion/bash/docker \
  -o ~/.autocomplete/docker-completion.bash

echo -e "\n *** Fetching docker-compose autocomplete script. ***"
curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose --version | awk 'NR==1{print $NF}')/contrib/completion/bash/docker-compose \
  -o ~/.autocomplete/docker-compose-completion.bash

echo -e "\n *** Fetching docker-machine autocomplete script. ***"
curl -L https://raw.githubusercontent.com/docker/machine/master/contrib/completion/bash/docker-machine.bash \
  -o ~/.autocomplete/docker-machine-completion.bash
