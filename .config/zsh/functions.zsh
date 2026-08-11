# Custom shell functions
# Auto-sourced by Oh My Zsh from $ZSH_CUSTOM during `source $ZSH/oh-my-zsh.sh`.

# Attach to (or create) a persistent tmux "main" session.
tmain() {
  [ -n "$TMUX" ] && exec zsh

  if ! tmux has-session -t main 2>/dev/null; then
    tmux new-session -d -s main
  fi

  exec tmux attach -t main
}

# Launch yazi as a navigation tool: on quit, cd the shell into the directory
# yazi was last in (via --cwd-file). Official wrapper from the yazi docs.
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# Fuzzy-pick any open window (across all workspaces) and focus it.
# aerospace prints "<window-id> | <app> | <title>", so {1} is the window id.
# `become` replaces fzf with the focus call, so nothing lingers on screen.
ff() {
  aerospace list-windows --all |
    fzf --bind 'enter:become(aerospace focus --window-id {1})'
}

# Open a repo under ~/git in nvim, with tab-completion of subdirectories.
nv() {
  nvim "$HOME/git/$1"
}

_nv_completion() {
  local -a subdirs
  subdirs=(${HOME}/git/*(N/))
  subdirs=(${subdirs:t})
  _describe 'git subdirectory' subdirs
}
compdef _nv_completion nv
