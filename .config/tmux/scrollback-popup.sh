#!/bin/sh
set -eu
pane=${1:?origin pane required}
umask 077
capture=$(mktemp "${TMPDIR:-/tmp}/tmux-scrollback.XXXXXX")
trap 'rm -f "$capture"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
tmux capture-pane -p -S - -t "$pane" > "$capture"
nvim --cmd 'let g:dotfiles_no_session = 1' '+normal G' "$capture"
