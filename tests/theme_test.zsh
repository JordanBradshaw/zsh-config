#!/usr/bin/env -S zsh -f
#
# Tests for theme/yupps.zsh-theme.
# Run: zsh -f tests/theme_test.zsh

typeset -g REPO_DIR=${0:A:h:h}
typeset -g THEME=$REPO_DIR/theme/yupps.zsh-theme
source $REPO_DIR/tests/lib.zsh

load_theme() {
  zmodload zsh/zle
  typeset -g color_prompt=yes PROMPT_ALTERNATIVE=twoline
  source $THEME
}

# zshrinkwrap prints the upper prompt lines itself and hands zle only the last
# one, which zle draws from reset attributes. A color carried over from the
# line above is lost, so the last line must set its own.
test_twoline_bottom_line_sets_its_own_color() {
  load_theme
  local bottom=${PROMPT##*$'\n'}
  [[ $bottom == '%F{'* ]] || fail "bottom line has no color of its own: $bottom"
}

test_twoline_bottom_line_matches_top_line_color() {
  load_theme
  local top=${PROMPT%%┌*} bottom=${PROMPT##*$'\n'}
  assert_eq "${bottom%%└*}" "$top"
}

run_all
