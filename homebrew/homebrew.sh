#!/usr/bin/env bash

if ! [[ $OSTYPE == *"darwin"* ]]; then
  return
fi

eval "$(/opt/homebrew/bin/brew shellenv)"
