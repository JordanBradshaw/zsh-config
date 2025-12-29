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
# if (( ${+commands[ping]} )); then
#     alias ping="ping -c 5"
# fi

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
if (( ${+commands[duf]} )); then
    alias df="duf"
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

if (( ${+commands[btm]} )); then
    alias htop="btm"
fi
