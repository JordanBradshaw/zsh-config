# Debugging helpers: logs, network and zsh itself.
# Related helpers elsewhere: lsopenports, envdiff, whichall, lj-host, lj-debug.

# -------------------------------------------------------------------
# Logs
# -------------------------------------------------------------------

##? jerr [SINCE] - journal errors (err and worse) for this boot, or since SINCE (e.g. 1 hour ago)
function jerr() {
    if (( $# )); then
        command journalctl --no-pager -o short-iso -p err --since "$*"
    else
        command journalctl --no-pager -o short-iso -p err -b
    fi
}

##? jboot [N] - journal errors from boot N (default -1, the previous boot)
function jboot() {
    command journalctl --no-pager -o short-iso -p err -b "${1:--1}"
}

##? jfollow UNIT - follow a unit's journal
function jfollow() {
    if (( $# != 1 )); then
        print -u2 "usage: jfollow UNIT"
        return 2
    fi
    command journalctl -o short-iso -f -u "$1"
}

##? failed - failed systemd units, system and user
function failed() {
    print -P "%BSystem%b"
    command systemctl --failed --no-pager
    print -P "\n%BUser%b"
    command systemctl --user --failed --no-pager
}

##? kmsg - kernel warnings and errors for this boot
function kmsg() {
    command journalctl --no-pager -o short-iso -k -b -p warning
}

# -------------------------------------------------------------------
# Network
# -------------------------------------------------------------------

##? port PORT - sockets on PORT (listening or connected) and their processes
function port() {
    if [[ $1 != <1-65535> ]]; then
        print -u2 "usage: port PORT"
        return 2
    fi
    # Other users' processes are only shown to root.
    local -a pre
    (( EUID )) && (( ${+commands[sudo]} )) && pre=(sudo)
    command $pre ss -tunap "( sport = :$1 or dport = :$1 )"
}

##? tcpcheck HOST PORT - can HOST:PORT be reached (3 second timeout)
function tcpcheck() {
    if (( $# != 2 )); then
        print -u2 "usage: tcpcheck HOST PORT"
        return 2
    fi
    command nc -zv -w 3 "$1" "$2"
}

##? dnsq NAME - resolve NAME with the system resolver and with 1.1.1.1, to spot local DNS problems
function dnsq() {
    if (( $# != 1 )); then
        print -u2 "usage: dnsq NAME"
        return 2
    fi
    print -P "%BSystem resolver%b"
    if (( ${+commands[resolvectl]} )); then
        command resolvectl query -- "$1"
    else
        getent ahosts "$1"
    fi
    print -P "\n%Bdig @1.1.1.1%b"
    command dig +short @1.1.1.1 "$1"
}

##? netinfo - interfaces, routes and DNS servers
function netinfo() {
    print -P "%BInterfaces%b"
    command ip -br -c addr
    print -P "\n%BRoutes%b"
    command ip -c route
    if (( ${+commands[resolvectl]} )); then
        print -P "\n%BDNS%b"
        command resolvectl dns
    fi
}

# -------------------------------------------------------------------
# zsh
# -------------------------------------------------------------------

##? zsh-bench [N] - time interactive zsh startup N times (default 5); deferred plugins are not counted
function zsh-bench() {
    emulate -L zsh
    zmodload zsh/datetime
    local -i n=${1:-5} i
    local -F start ms total=0

    for (( i = 1; i <= n; i++ )); do
        start=$EPOCHREALTIME
        command zsh -i -c exit </dev/null >/dev/null 2>&1
        ms=$(( (EPOCHREALTIME - start) * 1000 ))
        (( total += ms ))
        printf 'run %d: %.0f ms\n' $i $ms
    done
    printf 'average: %.0f ms\n' $(( total / n ))
}

##? zsh-prof - profile interactive zsh startup with zprof (needs the ZSH_PROF line in .zshrc)
function zsh-prof() {
    ZSH_PROF=1 command zsh -i -c zprof
}

##? wherefrom NAME - what NAME is and where it is defined
function wherefrom() {
    emulate -L zsh
    zmodload -F zsh/parameter p:functions_source
    if (( $# != 1 )); then
        print -u2 "usage: wherefrom NAME"
        return 2
    fi

    local name=$1 file
    integer found=0
    if (( ${+aliases[$name]} )); then
        print -r -- "alias: $name=${(q+)aliases[$name]}"
        found=1
    fi
    if (( ${+functions[$name]} )); then
        print -r -- "function: ${functions_source[$name]:-(defined interactively)}"
        found=1
    fi
    if (( ${+builtins[$name]} )); then
        print -r -- "builtin: $name"
        found=1
    fi
    for file in ${(f)"$(whence -ap -- $name 2>/dev/null)"}; do
        if [[ $file:A != $file ]]; then
            print -r -- "command: $file -> $file:A"
        else
            print -r -- "command: $file"
        fi
        found=1
    done

    (( found )) || { print -u2 "wherefrom: $name not found"; return 1 }
}

##? ztrace CMD [ARGS...] - run one command with xtrace, in a subshell
function ztrace() {
    (
        PS4='+%x:%I> '
        setopt xtrace
        "$@"
    )
}
