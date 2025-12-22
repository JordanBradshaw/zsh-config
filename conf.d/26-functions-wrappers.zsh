##? wrap-sudo sudo wrapper which is able to expand aliases and handle noglob/nocorrect builtins
function wrap-sudo() {
    # 

    emulate -L zsh

    integer glob=1
    local -a run
    run=(command sudo)
    if [[ ${#} -gt 1 && ${1} = -u ]]; then
        run+=(${1} ${2})
        shift; shift
    fi
    while (( ${#} )); do
        case "${1}" in
            command|exec|-) shift; break ;;
            nocorrect) shift ;;
            noglob) glob=0; shift ;;
            *) break ;;
        esac
    done
    if (( glob )); then
        ${run} $~==*
    else
        ${run} $==*
    fi

    # vim: ft=zsh
}
##? color man without correction suggestions
function wrap-man() {
        emulate -L zsh 
# with new groff we need to explicitly ask for color support
    local -x MANROFFOPT=-c

    # set originally "bold" as "bold and red"
    # set originally "underline" as "underline and green"

    # termcap codes
    # md    start bold
    # mb    start blink
    # me    turn off bold, blink and underline
    # so    start standout (reverse video)
    # se    stop standout
    # us    start underline
    # ue    stop underline
    local -x LESS_TERMCAP_md=$(echoti bold; echoti setaf 1)
    local -x LESS_TERMCAP_mb=$(echoti blink)
    local -x LESS_TERMCAP_me=$(echoti sgr0)
    local -x LESS_TERMCAP_so=$(echoti smso)
    local -x LESS_TERMCAP_se=$(echoti rmso)
    local -x LESS_TERMCAP_us=$(echoti smul; echoti setaf 2)
    local -x LESS_TERMCAP_ue=$(echoti sgr0)

    nocorrect command man ${@}

    # vim: ft=zsh
}
