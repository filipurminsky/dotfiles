# ~/.zshrc — Oh My Zsh bootstrap.
#
# Personal config is split into auto-loaded files under $ZSH_CUSTOM
# (~/.config/zsh/*.zsh), which Oh My Zsh sources for you:
#   exports.zsh    environment variables
#   aliases.zsh    personal aliases
#   functions.zsh  shell functions (tmain, nv, y, ...)
#   tools.zsh      tool init (fnm, sdkman, zoxide, iterm2)
# Only theme-dependent prompt code lives here (see bottom), because it
# must run after Oh My Zsh loads the theme.

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Keep personal customizations OUTSIDE the OMZ install (which is its own git
# repo) so they can be tracked in the dotfiles repo. Must be set before
# sourcing oh-my-zsh.sh. Plugins/completions/themes live here too.
export ZSH_CUSTOM="$HOME/.config/zsh"

# Theme — see https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"
DEFAULT_USER=$(whoami)

# Which plugins to load (standard plugins in $ZSH/plugins/, custom in
# $ZSH_CUSTOM/plugins/). Add wisely — too many slow down shell startup.
#
# zsh-vi-mode is skipped inside Neovim's terminal ($NVIM is set there): nvim
# already provides modal editing for the terminal buffer, and two vi layers
# fight over Esc. In a real terminal / tmux it loads normally.
plugins=(zsh-syntax-highlighting zsh-autosuggestions git aws kubectl docker terraform)
[[ -z $NVIM ]] && plugins+=(zsh-vi-mode)

# zsh-vi-mode treats a lone Esc as "exit insert mode" once ZVM_ESCAPE_KEYTIMEOUT
# elapses (default 0.03s) -- far too short to also type Esc+. (insert-last-word,
# bound in the post-init hook below), so that chord never registers. Widen the
# window so Esc-prefixed insert bindings are reachable. Trade-off: a bare
# Esc->normal now waits this long. 0.2s balances both; raise toward 0.3 if Esc+.
# gets missed, lower for snappier mode switches.
ZVM_ESCAPE_KEYTIMEOUT=0.2

source $ZSH/oh-my-zsh.sh

# --- Theme-dependent prompt config ----------------------------------------
# Must stay here: it wraps the agnoster theme's build_prompt, so the theme
# has to be loaded first (Oh My Zsh loads it inside the source line above,
# after the $ZSH_CUSTOM/*.zsh files).

# zsh-vi-mode: single-char mode indicator (i/n/v/V/r) as the leftmost
# agnoster segment. Drawn via a wrapper around build_prompt so we don't
# edit the theme file (survives Oh My Zsh updates).
prompt_vi_mode() {
  [[ -n $ZVM_MODE ]] || return   # no segment when zsh-vi-mode isn't loaded (inside nvim)
  local char bg
  case $ZVM_MODE in
    $ZVM_MODE_NORMAL)      char='n'; bg='blue'   ;;
    $ZVM_MODE_INSERT)      char='i'; bg='green'  ;;
    $ZVM_MODE_VISUAL)      char='v'; bg='yellow' ;;
    $ZVM_MODE_VISUAL_LINE) char='V'; bg='yellow' ;;
    $ZVM_MODE_REPLACE)     char='r'; bg='red'    ;;
    *)                     char='i'; bg='green'  ;;
  esac
  prompt_segment "$bg" black "$char"
}

# Date/time segment. Defined here (not in the theme file) so it survives Oh My
# Zsh updates and is tracked in the dotfiles repo.
prompt_time() {
  prompt_segment black cyan "%D{%Y-%m-%d %H:%M:%S}"
}

# "Where am I" context: replace agnoster's subtle user@host with a clear,
# distinctly-colored segment for Docker containers and SSH sessions. Nothing
# shows in a normal local shell. agnoster already calls prompt_context inside
# build_prompt, so overriding it here (after the theme) is all that's needed.
#   - container name isn't visible from inside Docker; we show $HOST (the
#     container hostname/ID) unless $PROMPT_BOX_NAME is set for a friendly label.
prompt_context() {
  if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    prompt_segment blue white " ${PROMPT_BOX_NAME:-$HOST}"
  fi
  if [[ -n "$SSH_CONNECTION" || -n "$SSH_TTY" ]]; then
    prompt_segment yellow black " %n@%m"
  elif [[ "$USERNAME" != "$DEFAULT_USER" ]]; then
    prompt_segment "${AGNOSTER_CONTEXT_BG:-black}" "${AGNOSTER_CONTEXT_FG:-default}" "%n@%m"
  fi
}

# Wrap agnoster's build_prompt, preserving $? so the error/status segment
# still works ( exit $ret restores the exit code build_prompt reads).
if (( ! ${+functions[_agnoster_orig_build_prompt]} )); then
  functions[_agnoster_orig_build_prompt]=${functions[build_prompt]}
fi
build_prompt() {
  local ret=$?
  prompt_vi_mode
  prompt_time
  ( exit $ret )
  _agnoster_orig_build_prompt
}

# Redraw the prompt the moment the mode changes.
function zvm_after_select_vi_mode() { zle reset-prompt; }

# fzf + atuin key tools. Defined once, initialized differently depending on
# whether zsh-vi-mode is loaded.
_init_keytools() {
  # fzf completion + key bindings (Ctrl-T files, Alt-C cd, Ctrl-R history).
  # Sourced first so atuin can override Ctrl-R below.
  source <(fzf --zsh)
  # atuin: SQLite-backed history search. Owns Ctrl-R (overrides fzf's).
  # --disable-up-arrow keeps Up as plain previous-command (predictable in vi).
  eval "$(atuin init zsh --disable-up-arrow)"
}

if [[ -z $NVIM ]]; then
  # zsh-vi-mode is loaded: its keymaps are applied AFTER .zshrc, so key setup
  # must run in its post-init hook or it gets clobbered.
  function zvm_after_init() {
    zvm_bindkey viins '^U' kill-whole-line   # restore Ctrl+U = kill whole line
    # Esc+. = insert last word of previous command (readline's yank-last-arg);
    # repeat to cycle through earlier commands. insert-last-word stays in insert
    # mode and inserts only the last word. Relies on the widened
    # ZVM_ESCAPE_KEYTIMEOUT above so the '.' is read before zsh-vi-mode decides
    # the lone Esc meant "exit insert mode".
    zvm_bindkey viins '^[.' insert-last-word
    _init_keytools
    # atuin binds Ctrl-R in BOTH viins and vicmd, clobbering vi's redo in
    # command mode. Give command-mode Ctrl-R back to redo (atuin keeps insert).
    bindkey -M vicmd '^R' redo
  }
else
  # Inside Neovim's terminal: no zsh-vi-mode, so init fzf/atuin directly now.
  _init_keytools
fi
