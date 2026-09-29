# -------------------------------------------------------------------
# sudo
#
# Trailing space makes zsh alias-expand the word after sudo, so
# `sudo ip a` becomes `sudo ip -c a`. Function wrappers below (ls, cat,
# grep, man, ...) are never passed to sudo; it runs the real binaries.
# -------------------------------------------------------------------
alias sudo='sudo '


# -------------------------------------------------------------------
# man
#
# A function rather than an alias, so `sudo man` still works.
# -------------------------------------------------------------------
if (( ${+commands[man]} )) && (( ${+functions[wrap-man]} )); then
    unalias man 2>/dev/null
    function man() {
        wrap-man "$@"
    }
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
                    command ls "$@"
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
# cat -> bat (batcat on Debian/Ubuntu)
#
# For normal "show me this file", use bat.
# Fall back when options indicate actual cat semantics are wanted.
# -------------------------------------------------------------------
if (( ${+commands[batcat]} || ${+commands[bat]} )); then
    unalias cat 2>/dev/null

    function cat() {
        local arg bat=bat
        (( ${+commands[batcat]} )) && bat=batcat

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
                    command cat "$@"
                    return
                    ;;
            esac
        done

        command $bat --paging=never "$@"
    }
fi


# -------------------------------------------------------------------
# grep -> ripgrep
#
# rg is only used when every option has the same meaning in both tools
# (e.g. -r, -h, -L, -s, -E, -I differ). Anything else goes to real grep.
# -------------------------------------------------------------------
if (( ${+commands[rg]} )); then
    unalias grep 2>/dev/null

    function grep() {
        emulate -L zsh
        setopt extended_glob
        local arg
        integer skip=0

        for arg in "$@"; do
            if (( skip )); then
                skip=0
                continue
            fi
            case "$arg" in
                --)
                    break
                    ;;
                --(ignore-case|invert-match|line-number|count|files-with-matches|word-regexp|line-regexp|only-matching|quiet|with-filename|no-filename|text|fixed-strings|perl-regexp|byte-offset|null))
                    ;;
                --(max-count|after-context|before-context|context|regexp|file|color)=*)
                    ;;
                --(max-count|after-context|before-context|context|regexp|file))
                    skip=1
                    ;;
                -[ABCm][0-9]##)
                    ;;
                -[ivnclwxoqHaFPb]#[ABCmef])
                    skip=1
                    ;;
                -[ivnclwxoqHaFPb]##)
                    ;;
                -?*)
                    command grep "$@"
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
                --no-pager|--pager-end|--output=*|-o*)
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
    unalias df 2>/dev/null
    function df() {
        if (( $# == 0 )); then
            command duf
        else
            command df "$@"
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
            command du "$@"
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
