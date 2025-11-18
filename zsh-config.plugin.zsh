
# --- Environment ---
# [[ -f "$0:A:h/env/exports.zsh" ]] && source "$0:A:h/env/exports.zsh"
# [[ -f "$0:A:h/env/paths.zsh"   ]] && source "$0:A:h/env/paths.zsh"
# [[ -f "$0:A:h/env/aliases.zsh" ]] && source "$0:A:h/env/aliases.zsh"

# --- Functions ---
# if [[ -d "$0:A:h/functions" ]]; then
#   for f in $0:A:h/functions/*.zsh; do
#     source "$f"
#   done
# fi

if [[ -d "$0:A:h/conf.d" ]]; then
  for _rc in $0:A:h/conf.d/*.zsh; do
    # Source non-tilde files.
    if [[ $_rc:t != '~'* ]]; then
      source "$_rc"
    fi
  done
fi

# --- Completions ---
# if [[ -d "$0:A:h/completions" ]]; then
#   fpath=("$0:A:h/completions" $fpath)
#   autoload -Uz compinit
#   compinit -d "${ZSH_COMPDUMP:-${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump}"
# fi

# --- Theme ---
if [[ -f "$0:A:h/theme/yupps.zsh-theme" ]]; then
    source "$0:A:h/theme/yupps.zsh-theme"
fi
