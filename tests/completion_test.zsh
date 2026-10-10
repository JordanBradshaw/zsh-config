#!/usr/bin/env -S zsh -f
#
# Tests for conf.d/50-completion.zsh.
# Run: zsh -f tests/completion_test.zsh
#
# Each test runs in a subshell with a temporary HOME, cache dir, PATH stubs and
# fpath stubs, against a real compinit.

emulate -L zsh
setopt extended_glob

typeset -g REPO_DIR=${0:A:h:h}
typeset -g CONF=$REPO_DIR/conf.d/50-completion.zsh
typeset -gi PASS=0 FAIL=0

# ---------------------------------------------------------------------------
# Helpers (used inside test subshells)
# ---------------------------------------------------------------------------

fail() {
  print -u2 "    $*"
  exit 1
}

assert_eq() {
  [[ $1 == $2 ]] || fail "${3:-assert_eq}: expected [$2], got [$1]"
}

# stub_cmd NAME [BODY]: create an executable in $STUB_BIN.
stub_cmd() {
  print -r -- "#!/bin/sh
${2:-exit 0}" >| $STUB_BIN/$1
  chmod +x $STUB_BIN/$1
}

# stub_comp NAME COMMANDS...: create a completion function in $STUB_FPATH.
stub_comp() {
  local name=$1; shift
  print -r -- "#compdef $*
return 0" >| $STUB_FPATH/$name
}

sandbox() {
  SANDBOX=$(mktemp -d)
  export HOME=$SANDBOX/home XDG_CACHE_HOME=$SANDBOX/cache
  STUB_BIN=$SANDBOX/bin STUB_FPATH=$SANDBOX/fpath
  mkdir -p $HOME/.ssh $XDG_CACHE_HOME $STUB_BIN $STUB_FPATH
  path=($STUB_BIN /usr/bin /bin)
  fpath=($STUB_FPATH $fpath)
}

load_conf() {
  rehash
  autoload -Uz compinit
  compinit -D -i
  source $CONF
}

run_test() {
  local name=$1
  (
    sandbox
    trap 'rm -rf $SANDBOX' EXIT
    $name
  )
  if (( $? == 0 )); then
    (( PASS++ ))
    print "  ok   $name"
  else
    (( FAIL++ ))
    print "  FAIL $name"
  fi
}

# ---------------------------------------------------------------------------
# SSH hosts
# ---------------------------------------------------------------------------

test_ssh_hosts_skips_wildcards() {
  print -l 'Host zbox nuc' '  HostName 10.0.0.1' 'Host *' 'Host cuas*' 'host trillium' \
    >| $HOME/.ssh/config
  load_conf
  _zc_ssh_hosts $HOME/.ssh/config
  assert_eq "${(j: :)${(@o)reply}}" "nuc trillium zbox"
}

test_ssh_hosts_follow_includes() {
  mkdir -p $HOME/.ssh/config.d $HOME/other
  print -l 'Include config.d/*' 'Include ~/other/extra' 'Host main' >| $HOME/.ssh/config
  print -l 'Host work-a work-b' >| $HOME/.ssh/config.d/work
  print -l 'Host lab' 'Include ~/.ssh/config' >| $HOME/other/extra
  load_conf
  _zc_ssh_hosts $HOME/.ssh/config
  assert_eq "${(j: :)${(@o)reply}}" "lab main work-a work-b"
}

test_ssh_hosts_missing_config() {
  load_conf
  _zc_ssh_hosts $HOME/.ssh/config
  assert_eq "${#reply}" 0
}

test_ssh_zstyles_cover_ssh_family() {
  print -l 'Host zbox' >| $HOME/.ssh/config
  load_conf
  local cmd
  local -a hosts users
  for cmd in ssh scp sftp rsync ssh-copy-id mosh sshfs; do
    zstyle -a ":completion::complete:${cmd}:argument-1:hosts" hosts hosts
    assert_eq "$hosts" "zbox" "hosts for $cmd"
    zstyle -a ":completion::complete:${cmd}:argument-1:users" users users
    assert_eq "$users" "root $USER" "users for $cmd"
  done
}

# ---------------------------------------------------------------------------
# Generated completions
# ---------------------------------------------------------------------------

stub_generator() {
  stub_cmd foo "echo run >> $SANDBOX/runs
cat <<'EOF'
#compdef foo
_foo() { return 0 }
compdef _foo foo
EOF"
}

test_gencomp_creates_cache_and_registers() {
  stub_generator
  load_conf
  _zc_gencomp foo completion zsh
  [[ -s $XDG_CACHE_HOME/zsh/gencomp/_foo ]] || fail "cache not written"
  assert_eq "$_comps[foo]" "_foo"
}

test_gencomp_reuses_fresh_cache() {
  stub_generator
  load_conf
  _zc_gencomp foo completion zsh
  _zc_gencomp foo completion zsh
  assert_eq "$(wc -l < $SANDBOX/runs | tr -d ' ')" 1
}

test_gencomp_regenerates_when_binary_newer() {
  stub_generator
  load_conf
  _zc_gencomp foo completion zsh
  touch -d '+1 minute' $STUB_BIN/foo
  _zc_gencomp foo completion zsh
  assert_eq "$(wc -l < $SANDBOX/runs | tr -d ' ')" 2
}

test_gencomp_skips_missing_command() {
  load_conf
  _zc_gencomp nosuchtool completion zsh 2>/dev/null
  [[ ! -e $XDG_CACHE_HOME/zsh/gencomp/_nosuchtool ]] || fail "cache written"
}

test_gencomp_drops_empty_output() {
  stub_cmd foo "exit 1"
  load_conf
  _zc_gencomp foo completion zsh 2>/dev/null
  [[ ! -e $XDG_CACHE_HOME/zsh/gencomp/_foo ]] || fail "empty cache kept"
}

# shtab-style scripts (tldr) only call compdef when eval'd; when sourced they
# run the completion function directly, which fails outside completion.
test_gencomp_registers_shtab_style_script() {
  stub_cmd foo "cat <<'EOF'
#compdef foo
_shtab_foo() { return 0 }
if [[ \$zsh_eval_context[-1] == eval ]]; then
  compdef _shtab_foo -N foo
else
  _shtab_foo
fi
EOF"
  load_conf
  _zc_gencomp foo --print-completion zsh
  assert_eq "$_comps[foo]" "_shtab_foo"
}

# Older cobra scripts (depot) have a #compdef header but never call compdef;
# they only work when autoloaded.
test_gencomp_registers_autoload_only_script() {
  stub_cmd foo "cat <<'EOF'
#compdef foo
_foo() { print called >> $SANDBOX/called }
if [ \"\$funcstack[1]\" = \"_foo\" ]; then
  _foo
fi
EOF"
  load_conf
  _zc_gencomp foo completion zsh
  assert_eq "$_comps[foo]" "_foo"
  _foo
  assert_eq "$(<$SANDBOX/called)" "called" "autoloaded body runs"
}

# ---------------------------------------------------------------------------
# Post-compinit setup
# ---------------------------------------------------------------------------

test_setup_registers_repo_functions() {
  load_conf
  _zc_completion_setup
  assert_eq "$_comps[mkcd]" "_directories" mkcd
  assert_eq "$_comps[pathappend]" "_directories" pathappend
  assert_eq "$_comps[pathprepend]" "_directories" pathprepend
  assert_eq "$_comps[bak]" "_files" bak
  assert_eq "$_comps[touchf]" "_files" touchf
  assert_eq "$_comps[tailf]" "_files" tailf
  assert_eq "$_comps[cdf]" "_files" cdf
  assert_eq "$_comps[lspath]" "_files" lspath
  assert_eq "$_comps[pathremove]" "_zc_pathremove" pathremove
  assert_eq "$_comps[ineachdir]" "_precommand" ineachdir
  assert_eq "$_comps[whichall]" "$_comps[whence]" whichall
}

test_setup_tree_uses_lsd_completion() {
  stub_comp _lsd lsd
  function tree() { : }
  load_conf
  _zc_completion_setup
  assert_eq "$_comps[tree]" "_lsd"
}

test_setup_maps_fdfind_to_fd() {
  stub_cmd fdfind
  stub_comp _fd fd
  load_conf
  _zc_completion_setup
  assert_eq "$_comps[fdfind]" "_fd"
}

test_setup_gnu_generic_for_uncovered_tools() {
  stub_cmd duf
  load_conf
  _zc_completion_setup
  assert_eq "$_comps[duf]" "_gnu_generic"
}

test_setup_keeps_existing_completion() {
  stub_cmd btm
  stub_comp _btm btm
  load_conf
  _zc_completion_setup
  assert_eq "$_comps[btm]" "_btm"
}

test_setup_generates_tldr_completion() {
  stub_cmd tldr '[ "$1" = --print-completion ] || exit 1
echo "#compdef tldr"
echo "_tldr_gen() { return 0 }"
echo "compdef _tldr_gen tldr"'
  load_conf
  _zc_completion_setup
  assert_eq "$_comps[tldr]" "_tldr_gen"
}

test_setup_skips_uninstalled_tools() {
  load_conf
  (( ! $+commands[eget] )) || fail "eget unexpectedly on sandbox PATH"
  _zc_completion_setup
  assert_eq "${_comps[eget]-unset}" "unset"
}

test_setup_runs_once() {
  load_conf
  (( ${precmd_functions[(I)_zc_completion_setup]:-0} )) || fail "hook not registered"
  _zc_completion_setup
  (( ! ${precmd_functions[(I)_zc_completion_setup]:-0} )) || fail "hook not removed"
}

# ---------------------------------------------------------------------------
# zstyles
# ---------------------------------------------------------------------------

test_approximate_scales_with_length() {
  load_conf
  local v PREFIX=abcdefghi SUFFIX=
  zstyle -s ':completion::approximate:::' max-errors v
  assert_eq "$v" "3 numeric"
}

test_topic_zstyles() {
  load_conf
  zstyle -t ':completion::complete:docker:argument-1:' option-stacking || fail docker
  zstyle -t ':completion::complete:man:argument-1:manuals' separate-sections || fail man
  zstyle -t ':completion::complete:make:argument-1:targets' call-command || fail make
  zstyle -t ':completion::complete:cd:argument-1:' squeeze-slashes || fail squeeze
  local v
  zstyle -s ':completion::complete:rm:argument-rest:' ignore-line v
  assert_eq "$v" "other" ignore-line
  zstyle -s ':completion::complete:-command-::functions' ignored-patterns v
  [[ _foo == ${~v} ]] || fail "functions ignore _*"
}

test_fzf_tab_previews_defined() {
  load_conf
  local ctx v
  for ctx in \
    ':fzf-tab:complete:kill:argument-rest' \
    ':fzf-tab:complete:systemctl-status:argument-1' \
    ':fzf-tab:complete:git-log:argument-1' \
    ':fzf-tab:complete:git-diff:argument-rest' \
    ':fzf-tab:complete:git-checkout:argument-rest' \
    ':fzf-tab:complete:man:argument-1' \
    ':fzf-tab:complete:-command-:' \
    ':fzf-tab:complete:-parameter-:' \
    ':fzf-tab:complete:nvim:argument-rest'; do
    zstyle -s $ctx fzf-preview v || fail "no preview for $ctx"
  done
}

test_no_fzf_flags_override() {
  load_conf
  [[ -z $(zstyle -L ':fzf-tab:*' fzf-flags) ]] || fail "fzf-flags set"
}

test_git_diff_preview_without_preview_columns() {
  (( $+commands[git] )) || return 0
  load_conf
  cd $SANDBOX
  git init -q repo && cd repo
  print one >| f && git add f && git -c user.name=t -c user.email=t@t commit -qm init
  print two >| f
  unset FZF_PREVIEW_COLUMNS
  local v out word=f group='[modified file]'
  zstyle -s ':fzf-tab:complete:git-diff:argument-rest' fzf-preview v
  out=$(eval $v 2>&1) || fail "preview failed: $out"
  [[ $out == *two* ]] || fail "diff missing: $out"
}

command_preview() {
  local v word=$1
  zstyle -s ':fzf-tab:complete:-command-:' fzf-preview v
  eval $v
}

test_command_preview_uses_offline_tldr_first() {
  stub_cmd tldr 'echo "TLDR src=$TLDR_PAGES_SOURCE_LOCATION args=$*"'
  load_conf
  local out=$(command_preview foo)
  assert_eq "$out" "TLDR src=file:///nonexistent args=--color foo"
}

test_command_preview_falls_back_without_tldr_page() {
  stub_cmd tldr 'exit 1'
  stub_cmd zzfoo
  load_conf
  rehash
  local out=$(command_preview zzfoo)
  [[ $out == "zzfoo is $STUB_BIN/zzfoo" ]] || fail "expected whence output, got: $out"
}

# ---------------------------------------------------------------------------

for t in ${(ok)functions[(I)test_*]}; do
  run_test $t
done

print "\n$PASS passed, $FAIL failed"
(( FAIL == 0 ))
