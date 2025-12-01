#!/usr/bin/env bash
# Module: direnv
# Description: direnv integration for project-specific environments
# Dependencies: direnv

if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi
