#!/usr/bin/env -S zsh -f
#
# Tests for conf.d/45-hooks.zsh and the atuin key binding in
# conf.d/40-keybindings.zsh.
# Run: zsh -f tests/hooks_test.zsh
#
# PATH holds only stubs, so the real zoxide/atuin/direnv never run.

typeset -g REPO_DIR=${0:A:h:h}
typeset -g CONF=$REPO_DIR/conf.d/45-hooks.zsh
source $REPO_DIR/tests/lib.zsh

typeset -g INIT_DIR

load_conf() {
  path=($STUB_BIN)
  INIT_DIR=$XDG_CACHE_HOME/zsh/init
  rehash
  source $CONF
}

# stub_init TOOL FUNC: TOOL logs its arguments to $SANDBOX/runs and prints
# an init script defining FUNC.
stub_init() {
  stub_cmd $1 "echo \"$1 \$*\" >> $SANDBOX/runs
echo 'function $2() { print -r -- $2 \"\$@\" }'"
}

runs() {
  local -a lines
  [[ -f $SANDBOX/runs ]] && lines=("${(@f)$(<$SANDBOX/runs)}")
  print $#lines
}

# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

test_no_tools_no_hooks() {
  load_conf
  (( ! $+functions[z] )) || fail "z defined without zoxide"
  [[ ! -e $INIT_DIR ]] || fail "cache dir created"
}

test_zoxide_init_is_sourced() {
  stub_init zoxide z
  load_conf
  assert_eq "$(z foo)" "z foo"
}

test_zoxide_keeps_cd() {
  stub_init zoxide z
  load_conf
  assert_eq "$(<$SANDBOX/runs)" "zoxide init zsh"
}

test_atuin_leaves_up_arrow_alone() {
  stub_init atuin _atuin_stub
  load_conf
  assert_eq "$(<$SANDBOX/runs)" "atuin init zsh --disable-up-arrow"
}

test_direnv_hook_is_sourced() {
  stub_init direnv _direnv_hook
  load_conf
  assert_eq "$(<$SANDBOX/runs)" "direnv hook zsh"
  assert_eq "$(_direnv_hook)" "_direnv_hook"
}

# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------

test_cache_reused() {
  stub_init zoxide z
  load_conf
  load_conf
  assert_eq "$(runs)" 1
  [[ -s $INIT_DIR/zoxide.zsh ]] || fail "no cache file"
}

test_cache_rebuilt_when_binary_newer() {
  stub_init zoxide z
  load_conf
  /usr/bin/touch -d '+1 minute' $STUB_BIN/zoxide
  load_conf
  assert_eq "$(runs)" 2
}

test_cache_rebuilt_when_command_changes() {
  stub_init zoxide z
  load_conf
  print -l '# /old/zoxide init zsh --old' 'function z() { print stale }' >| $INIT_DIR/zoxide.zsh
  /usr/bin/touch -d '+1 minute' $INIT_DIR/zoxide.zsh
  load_conf
  assert_eq "$(runs)" 2
  assert_eq "$(z foo)" "z foo"
}

test_failed_init_is_not_cached() {
  stub_cmd zoxide 'exit 1'
  load_conf 2>/dev/null
  [[ ! -e $INIT_DIR/zoxide.zsh ]] || fail "cached a failed init"
  (( ! $+functions[z] )) || fail "z defined"
}

# ---------------------------------------------------------------------------
# atuin key binding (conf.d/40-keybindings.zsh)
# ---------------------------------------------------------------------------

test_ctrl_r_bound_to_atuin_up_untouched() {
  zmodload zsh/zle
  function _w() { : }
  zle -N atuin-search _w
  zle -N atuin-search-viins _w
  zle -N atuin-search-vicmd _w
  zle -N history-substring-search-up _w
  zle -N history-substring-search-down _w
  source $REPO_DIR/conf.d/40-keybindings.zsh
  _zc_bind_keys
  assert_eq "$(bindkey -M emacs '^R')" '"^R" atuin-search' emacs
  assert_eq "$(bindkey -M viins '^R')" '"^R" atuin-search-viins' viins
  assert_eq "$(bindkey -M vicmd '^R')" '"^R" atuin-search-vicmd' vicmd
  assert_eq "$(bindkey -M viins '^[[A')" '"^[[A" history-substring-search-up' up
}

test_ctrl_r_untouched_without_atuin() {
  zmodload zsh/zle
  source $REPO_DIR/conf.d/40-keybindings.zsh
  local before=$(bindkey -M emacs '^R')
  _zc_bind_keys
  assert_eq "$(bindkey -M emacs '^R')" "$before"
}

# ---------------------------------------------------------------------------

run_all
