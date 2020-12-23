#!/usr/bin/env bash

eval "$(ssh-agent -s)"
for _key in $(ls -A ~/.ssh/*.pub); do
    # %???? removes '.pub' to target
    # corresponding private key
    _priv="${_key%????}"
    ssh-add -q "${_priv}"
done
