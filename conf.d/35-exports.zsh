
#
# Pager (bat-based man pager)
#
# if (( ${+commands[bat]} )); then
#     export MANPAGER="sh -c 'col -bx | bat --language=man --style=plain'"
# fi
if (( ${+commands[bat]} )); then
    export MANPAGER="sh -c 'col -bx | bat --language=man --style=plain'"
elif (( ${+commands[most]} )); then
    export MANPAGER="most -s"
else
    export MANPAGER="less -R"
fi

#
# less defaults
#
if (( ${+commands[less]} )); then
    export LESS="-R"
    export LESSHISTFILE="-"
fi

#
# fd-find + fzf integration
#
if (( ${+commands[fdfind]} )); then
    export FZF_DEFAULT_COMMAND="fdfind --type f"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

if (( ${+commands[fzf]} )); then
    export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border"
fi

#
# fzf preview using bat
#
if (( ${+commands[fzf]} && ${+commands[bat]} )); then
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
--preview 'bat --style=numbers --color=always {} | head -200'"
fi

#
# Pager (bat-based man pager)
#
# if (( ${+commands[bat]} )); then
#     export MANPAGER="sh -c 'col -bx | bat --language=man --style=plain'"
# fi
if (( ${+commands[bat]} )); then
    export MANPAGER="sh -c 'col -bx | bat --language=man --style=plain'"
elif (( ${+commands[most]} )); then
    export MANPAGER="most -s"
else
    export MANPAGER="less -R"
fi

#
# less defaults
#
if (( ${+commands[less]} )); then
    export LESS="-R"
    export LESSHISTFILE="-"
fi

#
# fd-find + fzf integration
#
if (( ${+commands[fdfind]} )); then
    export FZF_DEFAULT_COMMAND="fdfind --type f"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

if (( ${+commands[fzf]} )); then
    export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border"
fi

#
# fzf preview using bat
#
if (( ${+commands[fzf]} && ${+commands[bat]} )); then
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
--preview 'bat --style=numbers --color=always {} | head -200'"
fi
