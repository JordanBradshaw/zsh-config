# Completion: repo function completions, generated completions for tools that
# don't ship one, per-topic zstyles and fzf-tab previews.
#
# compdef calls run in a one-shot precmd hook, after ez-compinit's compinit,
# so `_comps` can be checked to avoid replacing real completions.
#
# Keys set here must not also be set in ~/.zstyles, which is sourced later
# and would win.

autoload -Uz add-zsh-hook

##? _zc_ssh_hosts FILE... - set $reply to Host names from ssh configs, following Include
function _zc_ssh_hosts() {
  emulate -L zsh
  setopt extended_glob

  reply=()
  local -a queue=("$@") seen=() words matches
  local file line inc

  while (( $#queue )); do
    file=$queue[1]
    shift queue
    [[ -r $file ]] && (( ! ${seen[(Ie)$file]} )) || continue
    seen+=($file)

    for line in "${(@f)$(<$file)}"; do
      words=(${=line%%\#*})
      (( $#words )) || continue
      case ${(L)words[1]} in
        host)
          reply+=(${words[2,-1]:#*[*?!]*})
          ;;
        include)
          for inc in $words[2,-1]; do
            inc=${inc/#\~/$HOME}
            [[ $inc == /* ]] || inc=$HOME/.ssh/$inc
            matches=(${~inc}(N))
            queue+=($matches)
          done
          ;;
      esac
    done
  done

  reply=(${(u)reply})
}

##? _zc_gencomp CMD ARGS... - cache `CMD ARGS` completion output and source it
function _zc_gencomp() {
  emulate -L zsh
  local bin=${commands[$1]}
  [[ -n $bin ]] || return 1

  # Not oh-my-zsh's $ZSH_CACHE_DIR/completions: that is on fpath, and these
  # scripts are meant to be sourced, not autoloaded.
  local dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/gencomp
  local cache=$dir/_$1

  if [[ ! -s $cache || $bin -nt $cache ]]; then
    [[ -d $dir ]] || mkdir -p $dir
    if "$@" >| $cache.tmp 2>/dev/null && [[ -s $cache.tmp ]]; then
      mv -f $cache.tmp $cache
    else
      rm -f $cache.tmp
    fi
  fi

  [[ -s $cache ]] || return 1
  # eval, not source: shtab scripts (tldr) only register via compdef when
  # $zsh_eval_context ends in eval.
  eval "$(<$cache)"

  # Autoload-style scripts (older cobra, e.g. depot) define _<cmd> but never
  # call compdef.
  if (( ! ${+_comps[$1]} && ${+functions[_$1]} )); then
    compdef _$1 $1
  fi
}

function _zc_pathremove() {
  compadd -a path
}

function _zc_completion_setup() {
  emulate -L zsh
  # compinit hasn't run yet; try again next prompt.
  (( ${+_comps} )) || return 0
  add-zsh-hook -d precmd _zc_completion_setup

  # Functions from this repo
  compdef _directories mkcd pathappend pathprepend
  compdef _files bak touchf tailf cdf lspath
  compdef _zc_pathremove pathremove
  compdef _precommand ineachdir
  compdef whichall=whence
  if (( ${+functions[tree]} && ${+_comps[eza]} )); then
    compdef tree=eza
  elif (( ${+functions[tree]} && ${+_comps[lsd]} )); then
    compdef tree=lsd
  fi

  # Debian/Ubuntu install fd as fdfind
  if (( ${+commands[fdfind]} && ! ${+_comps[fdfind]} && ${+functions[_fd]} )); then
    compdef _fd fdfind
  fi

  # Tools that can print their own completion script
  local gen
  local -a cmd
  for gen in \
    'lazygit completion zsh' \
    'sake completion zsh' \
    'depot completion zsh' \
    'opencode --completions zsh' \
    'pnpm completion zsh' \
    'uv generate-shell-completion zsh' \
    'just --completions zsh' \
    'kubectl completion zsh' \
    'helm completion zsh' \
    'tldr --print-completion zsh'; do
    cmd=(${=gen})
    if (( ${+commands[$cmd[1]]} && ! ${+_comps[$cmd[1]]} )); then
      _zc_gencomp $cmd
    fi
  done

  # Everything else: options parsed from --help
  local tool
  for tool in duf btm micro eget lazydocker mlr; do
    if (( ${+commands[$tool]} && ! ${+_comps[$tool]} )); then
      compdef _gnu_generic $tool
    fi
  done
}
add-zsh-hook precmd _zc_completion_setup


# -------------------------------------------------------------------
# SSH: hosts from ~/.ssh/config (and Include'd files), common users
# -------------------------------------------------------------------
_zc_ssh_cmds='(ssh|scp|sftp|rsync|ssh-copy-id|mosh|sshfs)'

_zc_ssh_hosts $HOME/.ssh/config
if (( $#reply )); then
  zstyle ":completion:*:${_zc_ssh_cmds}:*" hosts $reply
fi
zstyle ":completion:*:${_zc_ssh_cmds}:*" users root $USER
zstyle ":completion:*:${_zc_ssh_cmds}:*:hosts" ignored-patterns \
  localhost 'ip6-*' broadcasthost

unset _zc_ssh_cmds reply


# -------------------------------------------------------------------
# General
# -------------------------------------------------------------------
# Typo tolerance: one error per three typed characters, at most seven.
zstyle -e ':completion:*:approximate:*' max-errors \
  'reply=($(( ($#PREFIX + $#SUFFIX) / 3 > 7 ? 7 : ($#PREFIX + $#SUFFIX) / 3 )) numeric)'

# Hide completion internals and hook functions when completing commands
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec)|prompt_*)'

# a//b -> a/b instead of a/*/b
zstyle ':completion:*' squeeze-slashes true

# Don't offer arguments already on the command line
zstyle ':completion:*:(rm|kill|diff|cp|mv):*' ignore-line other

# Editors skip build artifacts
zstyle ':completion:*:*:(nvim|vim|micro|code):*:*files' ignored-patterns \
  '*.(o|pyc|zwc|class|swp)' '*~'

# sudo completes commands from root's PATH
zstyle ':completion:*:sudo:*' command-path \
  /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

# man: group pages by section
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.*' insert-sections true

# docker: complete after stacked short options, e.g. `docker run -it<TAB>`
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# make: list targets by running make
zstyle ':completion:*:make:*:targets' call-command true


# -------------------------------------------------------------------
# fzf-tab previews
#
# Only fzf-preview is set per context: a per-context fzf-flags would
# replace the global colors in ~/.zstyles.
# -------------------------------------------------------------------
if (( ${+commands[batcat]} )); then
  _zc_bat=batcat
elif (( ${+commands[bat]} )); then
  _zc_bat=bat
else
  _zc_bat=
fi

if (( ${+commands[delta]} )); then
  _zc_gdiff='git diff $word | delta --width=${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}}'
  _zc_gshow='git show $word | delta --width=${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}}'
else
  _zc_gdiff='git diff --color=always $word'
  _zc_gshow='git show --color=always $word'
fi

# Files and directories
zstyle ':fzf-tab:complete:(cat|bat|batcat|less|more|head|tail|nvim|vim|micro|code):*' fzf-preview \
  "if [[ -d \$realpath ]]; then
     command eza -1 --color=always --icons=always -- \$realpath 2>/dev/null ||
       command lsd -1 --color=always -- \$realpath 2>/dev/null ||
       command ls -1 --color=always -- \$realpath
   else
     ${_zc_bat:+command $_zc_bat --color=always --style=numbers --line-range=:200 -- \$realpath 2>/dev/null ||} command head -n 200 -- \$realpath
   fi"

# Processes: full command line
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'

# systemd units
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview \
  'SYSTEMD_COLORS=1 systemctl status -- $word'

# git
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview "$_zc_gdiff"
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
  "case \$group in
     '[commit tag]') git show --color=always \$word ;;
     *) $_zc_gshow ;;
   esac"
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
  "case \$group in
     '[modified file]') $_zc_gdiff ;;
     '[recent commit object name]') $_zc_gshow ;;
     *) git log --color=always \$word ;;
   esac"

# man pages
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview \
  'MANWIDTH=$FZF_PREVIEW_COLUMNS man -- $word 2>/dev/null'

# Commands: tldr page, man page, or what the name resolves to.
# The python tldr client downloads on a cache miss (~2s, and it ignores
# TLDR_NETWORK_ENABLED); a file:// source makes misses fail fast while cached
# pages, even stale ones, still render.
zstyle ':fzf-tab:complete:-command-:*' fzf-preview \
  '{ TLDR_PAGES_SOURCE_LOCATION=file:///nonexistent tldr --color $word ||
     MANWIDTH=$FZF_PREVIEW_COLUMNS man -- $word ||
     whence -v -- $word ||
     print -r -- ${(P)word} } 2>/dev/null'

# Variables: current value
zstyle ':fzf-tab:complete:(-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview \
  'print -r -- ${(P)word}'

unset _zc_bat _zc_gdiff _zc_gshow
