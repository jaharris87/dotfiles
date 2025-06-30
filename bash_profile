#!/bin/bash

if [[ "$(uname)" = "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  eval "$(pyenv init -)"
fi

if [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
fi
