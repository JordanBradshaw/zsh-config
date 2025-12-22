autoload -Uz compinit

# Cache location
zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p -- "${zcompdump:h}"

# Fast path (skip security checks). Remove -C if you prefer the safer default.
compinit -C -d "$zcompdump"
