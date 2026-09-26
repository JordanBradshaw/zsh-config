# -------------------------------------------------------------------
# man
# -------------------------------------------------------------------
if (( ${+commands[man]} )) && (( ${+functions[wrap-man]} )); then
    alias man="wrap-man"
fi


# -------------------------------------------------------------------
# fd -> fdfind
# This one is safe: same program, Debian/Ubuntu naming difference.
# -------------------------------------------------------------------
if (( ${+commands[fd]} )); then
    :
elif (( ${+commands[fdfind]} )); then
    alias fd="fdfind"
fi


# -------------------------------------------------------------------
# ls -> lsd
#
# Fall back to GNU ls for options/scripts that expect GNU semantics.
# Explicit /bin/ls or command ls always bypasses this anyway.
# -------------------------------------------------------------------
if (( ${+commands[lsd]} )); then
    unalias ls 2>/dev/null

    function ls() {
        emulate -L zsh
        local arg

        for arg in "$@"; do
            case "$arg" in
                --block-size=*|\
                --time-style=*|\
                --quoting-style=*|\
                --indicator-style=*|\
                --hide=*|\
                --ignore=*|\
                --format=*|\
                --sort=*|\
                --color=*|\
                --dired|\
                --full-time|\
                --author|\
                --context|\
                --zero)
                    command /bin/ls "$@"
                    return
                    ;;
            esac
        done

        command lsd --long --group-dirs first --icon always "$@"
    }

    tree() {
        command lsd --tree --depth=4 "$@"
    }
fi


# -------------------------------------------------------------------
# cat -> batcat
#
# For normal "show me this file", use bat.
# Fall back when options indicate actual cat semantics are wanted.
# -------------------------------------------------------------------
if (( ${+commands[batcat]} )); then
    unalias cat 2>/dev/null

    function cat() {
        local arg

        for arg in "$@"; do
            case "$arg" in
                -A|-b|-e|-E|-n|-s|-t|-T|-u|-v|\
                --show-all|\
                --number-nonblank|\
                --show-ends|\
                --number|\
                --squeeze-blank|\
                --show-tabs|\
                --show-nonprinting)
                    command /bin/cat "$@"
                    return
                    ;;
            esac
        done

        command batcat --paging=never "$@"
    }
fi
# cat() {
#     # stdin / pipes -> real cat
#     if (( $# == 0 )); then
#         command /bin/cat
#         return
#     fi

#     # options -> real cat
#     if [[ "$1" == -* ]]; then
#         command /bin/cat "$@"
#         return
#     fi

#     # ordinary files -> bat
#     command batcat --paging=never --style=plain "$@"
# }

# -------------------------------------------------------------------
# grep -> ripgrep
# -------------------------------------------------------------------
if (( ${+commands[rg]} )); then
    unalias grep 2>/dev/null

    function grep() {
        local arg

        for arg in "$@"; do
            case "$arg" in
                -*R*|-*E*|-*F*|-*G*|-*P*|\
                --dereference-recursive|\
                --extended-regexp|\
                --fixed-strings|\
                --basic-regexp|\
                --perl-regexp|\
                --include=*|\
                --exclude=*|\
                --exclude-dir=*|\
                --binary-files=*|\
                --directories=*|\
                --devices=*)
                    command /usr/bin/grep "$@"
                    return
                    ;;
            esac
        done

        command rg "$@"
    }
fi


# -------------------------------------------------------------------
# ip
#
# Same iproute2 command, just enable color.
# Very low-risk replacement.
# -------------------------------------------------------------------
if (( ${+commands[ip]} )); then
    alias ip="ip -c"
fi


# -------------------------------------------------------------------
# journalctl
#
# Still journalctl, so aliasing is generally safe.
# Don't force --no-pager if caller explicitly selects a pager/output
# behavior.
# -------------------------------------------------------------------
if (( ${+commands[journalctl]} )); then
    unalias journalctl 2>/dev/null

    function journalctl() {
        local arg

        for arg in "$@"; do
            case "$arg" in
                --no-pager|--pager-end|--output=*|-o)
                    command journalctl "$@"
                    return
                    ;;
            esac
        done

        command journalctl -o short-iso --no-pager "$@"
    }
fi


# -------------------------------------------------------------------
# df -> duf
#
# duf is NOT a drop-in df replacement. Only use it for bare `df`.
# Any arguments/options go to real df.
# -------------------------------------------------------------------
if (( ${+commands[duf]} )); then
    df() {
        if (( $# == 0 )); then
            command duf
        else
            command /bin/df "$@"
        fi
    }
else
    alias df="df -h"
fi


# -------------------------------------------------------------------
# du -> dust
#
# dust is also NOT command-line compatible with GNU du.
# Bare `du` gets dust; arguments go to real du.
# -------------------------------------------------------------------
if (( ${+commands[dust]} )); then
    unalias du 2>/dev/null
    function du() {
        if (( $# == 0 )); then
            command dust
        else
            command /usr/bin/du "$@"
        fi
    }
fi


# -------------------------------------------------------------------
# tar shortcuts
# These don't replace tar, so they're inherently safe.
# -------------------------------------------------------------------
if (( ${+commands[tar]} )); then
    alias targz="tar -xvzf"
    alias tarbz2="tar -xvjf"
    alias tarxz="tar -xvJf"
fi


# -------------------------------------------------------------------
# htop -> btm
#
# btm is not CLI-compatible with htop.
# Bare `htop` gets btm; arguments go to actual htop.
# -------------------------------------------------------------------
if (( ${+commands[btm]} )); then
    unalias htop 2>/dev/null
    function htop() {
        if (( $# == 0 )); then
            command btm
        elif (( ${+commands[htop]} )); then
            command htop "$@"
        else
            command btm "$@"
        fi
    }
fi