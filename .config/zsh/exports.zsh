# Environment variables
# Auto-sourced by Oh My Zsh from $ZSH_CUSTOM during `source $ZSH/oh-my-zsh.sh`.

export EDITOR="nvim"
export VISUAL="nvim"

# Pin the XDG config dir to ~/.config (the spec default) so tools that would
# otherwise use macOS-native dirs read from where this repo tracks them. e.g.
# aerc on macOS defaults to ~/Library/Preferences/aerc without this.
export XDG_CONFIG_HOME="$HOME/.config"

# Ensure a UTF-8 locale. macOS terminals set LANG already (this no-ops there),
# but a fresh Linux box / `docker exec` / bare SSH leaves it unset → LC_CTYPE
# falls back to POSIX, which makes Neovim/yazi/tmux drop Nerd Font icons. Default
# to C.UTF-8 (built into Ubuntu, no locale-gen needed) when nothing is set.
if [[ -z "$LANG" && -z "$LC_ALL" && -z "$LC_CTYPE" ]]; then
  export LANG="C.UTF-8"
fi

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
# Catppuccin Mocha, to match ghostty/tmux/nvim/yazi. Without an explicit
# --color fzf falls back to the terminal's 16 ANSI slots, which leaves the
# prompt/pointer/highlight colors visibly off-palette against everything else.
export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color=selected-bg:#45475a
  --color=border:#6c7086,label:#cdd6f4'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range :200 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --level=2 {}'"

# --- bat -------------------------------------------------------------------
# bat ships Catppuccin as a builtin theme (bat >= 0.25), so this needs no
# theme file. Previously "ansi", which tracked the terminal palette and so
# looked right in Ghostty but wrong anywhere the 16 ANSI colors differ — and
# it gave delta (which uses this same syntax theme) muted diff highlighting.
export BAT_THEME="Catppuccin Mocha"
