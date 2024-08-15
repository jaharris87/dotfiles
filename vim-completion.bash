#!/bin/bash

_vim() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    # List of file extensions to exclude
    opts=$(compgen -f -- "$cur" | grep -vE '\.o$|\.mod$')

    COMPREPLY=( $opts )
    return 0
}
complete -F _vim vim
