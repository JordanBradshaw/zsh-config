#!/bin/zsh

##? cdf -- jump to directory of a file
function cdf() {
#   local dir
#   dir=$(find ${1:-.} -type d 2>/dev/null | fzf +m) && cd "$dir"
  cd -- "${1:h}"
}

function ff() {
  local file
  file=$(fzf --preview 'batcat --style=numbers --color=always {}' --height=40%) && ${EDITOR:-nvim} "$file"
}

function bak(){
    local now f
    now=$(date +"%Y%m%d-%H%M%S")
    for f in "$@"; do
      if [[ ! -e "$f" ]]; then
        echo "file not found: $f" >&2
        continue
      fi
      cp -R "$f" "$f".$now.bak
    done
}

function post-autosuggestions() {
    # https://github.com/zsh-users/zsh-autosuggestions

# Set highlight color, default 'fg=8'.
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
    # Set key bindings.
    if [[ -n "$key_info" ]]; then
      # vi
      bindkey -M viins "$key_info[Control]F" vi-forward-word
      bindkey -M viins "$key_info[Control]E" vi-add-eol
    fi

}
##? https://github.com/zsh-users/zsh-history-substring-search
function post-history-substring-search() {

[[ -v terminfo ]] || zmodload zsh/terminfo
    for keymap in 'emacs' 'viins'; do
      bindkey -M "$keymap" "$terminfo[kcuu1]" history-substring-search-up
      bindkey -M "$keymap" "$terminfo[kcud1]" history-substring-search-down
    done
    
    # Vi
    bindkey -M vicmd "k" history-substring-search-up
    bindkey -M vicmd "j" history-substring-search-down
    
    # Emacs
    if [[ -n "$key_info" ]]; then
      bindkey -M emacs "$key_info[Control]P" history-substring-search-up
      bindkey -M emacs "$key_info[Control]N" history-substring-search-down
    fi
}
##? substenv - substitutes string parts with environment variables
function substenv() {

    if (( $# == 0 )); then
      subenv ZDOTDIR | subenv HOME
    else
      local sedexp="s|${(P)1}|\$$1|g"
      shift
      sed "$sedexp" "$@"
    fi
}

function update_completions() {
  emulate -L zsh; setopt local_options
  : ${__zsh_config_dir:=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}}
  local destdir=$__zsh_config_dir/completions
  mkdir -p $destdir

  echo "Getting git completions..."
  curl -fsSL -o $destdir/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
  curl -fsSL -o $destdir/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh

  echo "Generating starship completions..."
  local _starship=$destdir/_starship
  starship completions zsh >| $_starship
}
# update_completions "$@"

function zcompiledir() {
    emulate -L zsh; setopt localoptions extendedglob globdots globstarshort nullglob rcquotes
    autoload -U zrecompile

    local f
    local flag_clean=false
    [[ "$1" == "-c" ]] && flag_clean=true && shift
    if [[ -z "$1" ]] || [[ ! -d "$1" ]]; then
      echo "Bad or missing directory $1" && return 1
    fi

    if [[ $flag_clean == true ]]; then
      for f in "$1"/**/*.zwc(.N) "$1"/**/*.zwc.old(.N); do
        echo "removing $f" && command rm -f "$f"
      done
    else
      for f in "$1"/**/*.zsh{,-theme}; do
        echo "compiling $f" && zrecompile -pq "$f"
      done
    fi

}

##? cache output of generated compdef
function compdefcache {
emulate -L zsh

setopt local_options extended_glob

local cache_dir="${XDG_CACHE_HOME}/zsh/fpath"
local cache_file="${cache_dir}/_${1##/*}"

# revalidate cache every 20 hours
if [[ -r "${cache_file}" ]] && ! whence ${1} > /dev/null; then
    # remove cache file when it's present, but arg isn't executable
    echo "compdefcache ERROR: $1 isn't executable, removing cache file" >&2
    zf_rm -f "${cache_file}"
elif [[ ! -e "${cache_file}" || -n "${cache_file}"(#qN.mh+20) ]]; then
    # revalidate cache every 20 hours
    # cache miss, create compdef file
    if (( ${+commands[${1}]} )); then
        zf_mkdir -p "${cache_dir}"
        command "$@" > "${cache_file}"
    else
        echo "compdefcache ERROR: $1 is not available in PATH" >&2
    fi
else
    # cache hit, do nothing
fi

# vim: ft=zsh
}

function ineachdir() {
    # do something in each subdirectory of current directory

emulate -L zsh

{
    setopt localoptions localtraps

    # handle Ctrl+C interrupts
    TRAPINT () {
        echo ${fg[white]}"--- IED: Caught SIGINT, aborting."${fg[default]}
        return $(( 128 + $1 ))
    }

    local cwd dir exitcode ied_opts
    local -A ied_status
    cwd=${PWD}

    zparseopts -E -D -M -A ied_opts -- -ignore-errors -status-table i=-ignore-errors s=-status-table

    if [[ ${#} -eq 0 ]]; then
        cat <<- EOH
Usage: ineachdir [-i | --ignore-errors] [-s | --status-table] <command>

Perform specified <command> in each directory.

Arguments:
-i, --ignore-errors    Ignore <command> execution error,
                       continue to next dir

-s, --status-table     Show status table at the end

Example:
ineachdir -s git pull --prune
EOH
        return 0
    fi

    for dir in */; do
        echo ${fg[white]}"--- IED: Executing '$@' in '${cwd}/${dir}'..."${fg[default]}
        cd "${cwd}/${dir}"
        $@
        exitcode=$?
        if (( ${+ied_opts[--status-table]} )); then
            ied_status[${dir}]=${exitcode}
        fi
        if [[ ${exitcode} -ne 0 ]]; then
            if (( ${+ied_opts[--ignore-errors]} )); then
                echo ${fg[yellow]}"--- IED: '$@' returned ${exitcode}, ignoring."${fg[default]}
            else
                echo ${fg[red]}"--- IED: '$@' returned ${exitcode}, aborting."${fg[default]}
                return $(( 128 + ${exitcode} ))
            fi
        fi
        echo
    done

    if (( ${+ied_opts[--status-table]} )); then
        echo ${fg[white]}"--- IED: Execution results"${fg[default]}
        for dir exitcode in ${(kv)ied_status}; do
            if [[ ${exitcode} -ne 0 ]]; then
                exitcode="${fg[yellow]}${exitcode}${fg[default]}"
            fi
            printf '%s\n' "${(r:35:)dir}: ${(%)exitcode}"
        done
    fi
} always {
    cd "${cwd}"
    unfunction TRAPINT
}

# vim: ft=zsh
}

##? recursively search for string, feed matches to fzf with preview, launch vim with selected match
function bag() {

emulate -L zsh

# use bat, if it's available...
local preview_cmd
if (( ${+commands[bat]} )); then
    preview_cmd='bat --style=numbers --color=always --highlight-line=${2} ${1}'
else
    # ...otherwise just highlight line with match using sed replace
    preview_cmd='sed -E "s/(.*'${*}'.*)/'$bg[grey]'\1'$reset_color'/gI;" < ${1}'
fi

# prefer rg over ag over grep
if (( ${+commands[rg]} )); then
    command rg --no-heading --line-number --smart-case --fixed-strings --color=always "${*}"
elif (( ${+commands[ag]} )); then
    command ag --nogroup --color --silent "${*}"
else
    command grep --line-number --recursive --ignore-case --color=always --no-messages "${*}"
fi | fzf --ansi --layout=reverse-list --no-sort --height=50% --delimiter=: \
         --preview=${preview_cmd} \
         --preview-window='right,50%,+{2}/2' \
         --bind='enter:become(${EDITOR} {1} +{2})'

# vim: ft=zsh
}


##? envdiff - compare current env to a clean login shell
envdiff() {
  diff -u --color=always =(env | sort) =(zsh -lic 'env' | sort) | less -R
}




function listallparameters() {
zmodload zsh/parameter
print -l ${(k)parameters}
# print -l ${(k)modules}
# print -l ${(k)options}

}

##? whichall - find all which respects zsh order
function whichall() {
    whence -a "$@"
}
##? mkdir + cd safely
function mkcd() {
    mkdir =p -- "$1" && cd -- "$1"
}
