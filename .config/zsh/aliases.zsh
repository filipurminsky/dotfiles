# Personal aliases
# Auto-sourced by Oh My Zsh from $ZSH_CUSTOM during `source $ZSH/oh-my-zsh.sh`.

alias v=nvim
alias vim=nvim
alias h='history'
alias hsi='history | grep -i'

# --- eza (modern ls) -------------------------------------------------------
alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -l --git --group-directories-first --icons=auto'
alias la='eza -la --git --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --icons=auto'

# --- bat (modern cat) ------------------------------------------------------
# --paging=never keeps cat-like behavior; adds syntax highlighting + numbers.
alias cat='bat --paging=never'

# --- lazygit ---------------------------------------------------------------
alias lg='lazygit'

# --- dotfiles (bare repo: git db in ~/.dotfiles, work-tree is $HOME) --------
# Use like git: `dotfiles status`, `dotfiles add ~/.zshrc`, `dotfiles push`.
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# fd and rg are best used as their own commands (their flags differ from
# find/grep), so they are intentionally left unaliased.
