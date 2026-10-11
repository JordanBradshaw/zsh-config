#!/usr/bin/env -S zsh -f
#
# Tests for the ls/tree/apt wrappers in conf.d/30-aliases.zsh and bin/zc-apt.
# Run: zsh -f tests/aliases_test.zsh
#
# PATH holds only stubs, so the real eza/lsd/nala on this machine never run.

typeset -g REPO_DIR=${0:A:h:h}
typeset -g CONF=$REPO_DIR/conf.d/30-aliases.zsh
typeset -g ZC_APT=$REPO_DIR/bin/zc-apt
source $REPO_DIR/tests/lib.zsh

# load_conf TOOL...: stub TOOL... (plus ls), then source the aliases.
load_conf() {
  path=($STUB_BIN)
  stub_echo ls "$@"
  rehash
  source $CONF
}

typeset -g EZA='eza --long --group-directories-first --icons=always --color=always'
typeset -g LSD='lsd --long --group-dirs first --icon always'

# ---------------------------------------------------------------------------
# ls: eza > lsd > ls
# ---------------------------------------------------------------------------

test_ls_prefers_eza() {
  load_conf eza lsd
  assert_eq "$(ls -la foo)" "$EZA -a foo"
}

test_ls_uses_lsd_without_eza() {
  load_conf lsd
  assert_eq "$(ls -la foo)" "$LSD -la foo"
}

test_ls_plain_without_eza_or_lsd() {
  load_conf
  (( ! $+functions[ls] )) || fail "ls wrapper defined"
}

test_ls_eza_drops_human_flag() {
  load_conf eza
  assert_eq "$(ls -lh)" "$EZA"
}

test_ls_eza_time_sort() {
  load_conf eza
  # eza's modified sort is oldest first; ls -t is newest first.
  assert_eq "$(ls -lt)" "$EZA --sort=modified --reverse" "-t"
  assert_eq "$(ls -ltr)" "$EZA --sort=modified" "-tr"
}

test_ls_eza_size_sort() {
  load_conf eza
  assert_eq "$(ls -S)" "$EZA --sort=size --reverse" "-S"
  assert_eq "$(ls -Sr)" "$EZA --sort=size" "-Sr"
}

test_ls_eza_reverse_alone() {
  load_conf eza
  assert_eq "$(ls -r)" "$EZA --reverse"
}

test_ls_eza_shared_long_options() {
  load_conf eza
  assert_eq "$(ls --all --reverse dir)" "$EZA --reverse --all dir"
}

test_ls_eza_double_dash() {
  load_conf eza
  assert_eq "$(ls -a -- -t)" "$EZA -a -- -t"
}

test_ls_eza_unknown_flag_uses_lsd() {
  load_conf eza lsd
  assert_eq "$(ls -v foo)" "$LSD -v foo"
}

test_ls_eza_unknown_flag_uses_ls_without_lsd() {
  load_conf eza
  assert_eq "$(ls -v foo)" "ls -v foo"
}

test_ls_gnu_only_option_uses_ls() {
  load_conf eza lsd
  assert_eq "$(ls --time-style=iso)" "ls --time-style=iso"
}

# ---------------------------------------------------------------------------
# tree
# ---------------------------------------------------------------------------

test_tree_prefers_eza() {
  load_conf eza lsd
  assert_eq "$(tree src)" \
    "eza --tree --level=4 --group-directories-first --icons=always --color=always src"
}

test_tree_uses_lsd_without_eza() {
  load_conf lsd
  assert_eq "$(tree src)" "lsd --tree --depth=4 src"
}

# ---------------------------------------------------------------------------
# apt -> bin/zc-apt (a script, so `sudo apt` can run it too)
# ---------------------------------------------------------------------------

typeset -g APT_OPTS='-o Acquire::Retries=5 -o APT::Get::Show-Versions=true'

test_apt_alias_points_at_script() {
  load_conf apt
  assert_eq "$aliases[apt]" "$ZC_APT"
  [[ -x $ZC_APT ]] || fail "$ZC_APT not executable"
}

test_apt_no_alias_without_apt() {
  load_conf
  (( ! $+aliases[apt] )) || fail "apt alias defined"
}

test_zc_apt_uses_nala() {
  stub_echo apt nala
  assert_eq "$(PATH=$STUB_BIN $ZC_APT install -y foo)" "nala install -y foo"
}

test_zc_apt_full_upgrade_maps_to_nala_upgrade() {
  stub_echo apt nala
  assert_eq "$(PATH=$STUB_BIN $ZC_APT full-upgrade)" "nala upgrade"
}

test_zc_apt_unsupported_subcommand_uses_apt() {
  stub_echo apt nala
  assert_eq "$(PATH=$STUB_BIN $ZC_APT policy foo)" "apt $APT_OPTS policy foo"
}

test_zc_apt_without_nala_uses_tuned_apt() {
  stub_echo apt
  assert_eq "$(PATH=$STUB_BIN $ZC_APT install foo)" "apt $APT_OPTS install foo"
}

test_zc_apt_leading_option_uses_apt() {
  stub_echo apt nala
  assert_eq "$(PATH=$STUB_BIN $ZC_APT -y install foo)" "apt $APT_OPTS -y install foo"
}

# ---------------------------------------------------------------------------

run_all
