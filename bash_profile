#!/bin/bash

eval "$(/opt/homebrew/bin/brew shellenv)"

if [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
fi
