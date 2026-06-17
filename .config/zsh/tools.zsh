# Third-party tool initialization (version managers, completions, integrations)
# Auto-sourced by Oh My Zsh from $ZSH_CUSTOM during `source $ZSH/oh-my-zsh.sh`.
#
# NOTE: Oh My Zsh runs compinit itself (once) BEFORE this file is sourced, so
# we no longer call compinit here. Completions that need to be on fpath at that
# point (e.g. Docker's _docker) live in $ZSH_CUSTOM/completions/, which OMZ adds
# to fpath before its compinit run.

# fnm — fast (Rust) Node version manager, replaces nvm. `--use-on-cd` auto-
# switches the Node version when entering a directory with a .nvmrc /
# .node-version file; `--version-file-strategy recursive` also picks one up
# from a parent directory. fnm is near-instant, so no lazy-load is needed.
# NOTE: fnm provides no `nvm` command, and Node versions installed via nvm are
# not visible to it — install versions with `fnm install` (e.g. `fnm install --lts`).
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd --version-file-strategy recursive)"

# SDKMAN (eager: puts java/gradle/mvn on PATH; lazy-loading would hide them)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# zoxide (provides the `z` command; smarter cd with frecency)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
