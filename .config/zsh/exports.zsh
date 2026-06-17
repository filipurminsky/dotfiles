# Environment variables
# Auto-sourced by Oh My Zsh from $ZSH_CUSTOM during `source $ZSH/oh-my-zsh.sh`.

export EDITOR="nvim"
export VISUAL="nvim"

# Read man pages in nvim (full vim navigation/search/syntax via :Man).
export MANPAGER='nvim +Man!'

export PATH="$HOME/.local/bin:$PATH"

# --- fzf -------------------------------------------------------------------
# Use fd (respects .gitignore, includes hidden files except .git) as the
# source for the default picker, Ctrl-T (files) and Alt-C (dirs). The key
# bindings themselves are wired up in ~/.zshrc, after zsh-vi-mode finishes
# rebinding keys.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range :200 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --level=2 {}'"

# --- bat -------------------------------------------------------------------
export BAT_THEME="ansi"
