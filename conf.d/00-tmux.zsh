# Start tmux, if it's first terminal tab, skip this on remote sessions and root/sudo
# Handoff to tmux early, as rest of the rc config isn't needed for this
# if (( ${+commands[tmux]} )) && [[ ! -v TMUX && ! -v SSH_TTY && ${EUID} != 0 ]] && ! tmux list-sessions &>/dev/null; then
#     exec tmux new-session
# fi

# Auto-attach tmux in interactive shells (optional)
# if [[ -o interactive ]] && (( $+commands[tmux] )); then
#   if [[ -z $TMUX && -z $VSCODE_GIT_IPC_HANDLE ]]; then
#     tmux new-session -A -s main
#   fi
# fi
