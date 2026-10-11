# Shell hooks: zoxide (z, zi), atuin (Ctrl-R history search) and direnv.
#
# Each tool's init script is cached, so startup doesn't run three extra
# processes. The cache is rebuilt when the binary changes or the init
# command does.
#
# atuin's Ctrl-R binding is (re)applied in 40-keybindings.zsh, because
# zsh-vi-mode resets key bindings on the first prompt.

zmodload -F zsh/files b:zf_mkdir b:zf_mv b:zf_rm

##? _zc_init_cache CMD ARGS... - set $REPLY to a cached copy of `CMD ARGS` output; fail if CMD is missing or fails
function _zc_init_cache() {
  emulate -L zsh
  local bin=${commands[$1]}
  [[ -n $bin ]] || return 1

  local dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init
  local cache=$dir/$1.zsh
  local header="# $bin ${@[2,-1]}"

  if [[ ! -s $cache || $bin -nt $cache || ${"$(<$cache)"%%$'\n'*} != $header ]]; then
    zf_mkdir -p $dir
    { print -r -- $header; "$bin" "${@[2,-1]}" } >| $cache.tmp 2>/dev/null
    if (( $? )) || [[ $(<$cache.tmp) == $header ]]; then
      zf_rm -f $cache.tmp
      return 1
    fi
    zf_mv -f $cache.tmp $cache
  fi
  REPLY=$cache
}

# Sourced at top level: these scripts set global variables.
_zc_init_cache zoxide init zsh && source $REPLY
_zc_init_cache atuin init zsh --disable-up-arrow && source $REPLY
_zc_init_cache direnv hook zsh && source $REPLY
unset REPLY
