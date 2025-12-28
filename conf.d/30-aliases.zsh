if (( ${+commands[man]} )); then
    alias man=wrap-man
fi

if (( ${+commands[bat]} )); then
    : # upstream name exists, do nothing
elif (( ${+commands[batcat]} )); then
    alias bat="batcat"
fi
if (( ${+commands[fd]} )); then
    : # upstream name exists, do nothing
elif (( ${+commands[fdfind]} )); then
    alias fd="fdfind"
fi


# lsd
if (( ${+commands[lsd]} )); then
    alias ls="lsd --long --group-dirs first --icon always"
    alias tree="lsd --tree --depth=4"
fi

# bat (Ubuntu/Debian binary name)
if (( ${+commands[batcat]} )); then
    alias cat="batcat --paging=never"
fi

# # fd-find (Ubuntu/Debian binary name)
# if (( ${+commands[fdfind]} )); then
#     alias fd="fdfind"
# fi

# ripgrep
if (( ${+commands[rg]} )); then
    alias grep="rg"
fi

# ip (iproute2)
if (( ${+commands[ip]} )); then
    alias ip="ip -c"
fi
if (( ${+commands[ping]} )); then
    alias ping="ping -c 5"
fi

# journalctl
if (( ${+commands[journalctl]} )); then
    alias journalctl="journalctl -o short-iso --no-pager"
fi

# apt (optional, commented out in original)
# if (( ${+commands[apt]} )); then
#     alias apt="apt -o=Dpkg::Progress-Fancy=1"
# fi

# df (human-readable)
if (( ${+commands[df]} )); then
    alias df="df -h"
fi

# du replacement (dust)
if (( ${+commands[dust]} )); then
    alias du="dust"
fi

# tar shortcuts
if (( ${+commands[tar]} )); then
    alias targz="tar -xvzf"
    alias tarbz2="tar -xvjf"
    alias tarxz="tar -xvJf"
fi

#
# Editor
#
if (( ${+commands[nano]} )); then
    export EDITOR="nano"
fi

#
# Pager (most)
#
if (( ${+commands[most]} )); then
    export PAGER="most"
    # export MANPAGER="most -s"
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
