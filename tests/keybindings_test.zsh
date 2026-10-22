#!/usr/bin/env -S zsh -f
#
# Tests for conf.d/40-keybindings.zsh.
# Run: zsh -f tests/keybindings_test.zsh

typeset -g REPO_DIR=${0:A:h:h}
typeset -g CONF=$REPO_DIR/conf.d/40-keybindings.zsh
source $REPO_DIR/tests/lib.zsh

load_conf() {
  zmodload zsh/zle
  source $CONF
  _zc_bind_keys
}

# Konsole and Yakuake send ESC O M for Shift+Enter. Unbound, zsh-vi-mode reads
# it as ESC (normal mode), O (open a line above) and a literal M.
test_shift_enter_bound_in_insert_mode() {
  load_conf
  assert_eq "$(bindkey -M viins '^[OM')" '"^[OM" _zc_insert_newline'
}

test_shift_enter_bound_in_normal_mode() {
  load_conf
  assert_eq "$(bindkey -M vicmd '^[OM')" '"^[OM" _zc_insert_newline'
}

test_shift_enter_bound_in_emacs_mode() {
  load_conf
  assert_eq "$(bindkey -M emacs '^[OM')" '"^[OM" _zc_insert_newline'
}

test_insert_newline_splits_at_cursor() {
  load_conf
  LBUFFER='echo' RBUFFER=' hi'
  _zc_insert_newline
  assert_eq "$LBUFFER" $'echo\n' left
  assert_eq "$RBUFFER" ' hi' right
}

test_insert_newline_at_end() {
  load_conf
  LBUFFER='echo hi' RBUFFER=
  _zc_insert_newline
  assert_eq "$LBUFFER$RBUFFER" $'echo hi\n'
}

# In normal mode the cursor sits on a character, so the break goes after it.
test_insert_newline_normal_mode_breaks_after_cursor_char() {
  load_conf
  KEYMAP=vicmd LBUFFER='echo hi' RBUFFER='!'
  _zc_insert_newline
  assert_eq "$LBUFFER$RBUFFER" $'echo hi!\n'
}

run_all
