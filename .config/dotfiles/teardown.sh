#!/usr/bin/env bash
# Reverse what bootstrap.sh set up, leaving the machine as it was before.
#
# Safety model: bootstrap.sh writes a manifest of what IT installed
# (~/.local/state/dotfiles/bootstrap.manifest). Teardown only undoes those
# entries, so anything that pre-existed — apt packages, Homebrew, Oh My Zsh,
# your login shell — is left untouched. Tool data and cloned configs live in
# known dotfiles-owned paths and are always removed.
#
# Usage: teardown.sh [-y|--yes]   (-y = don't prompt)
set -uo pipefail

ASSUME_YES=0
case "${1:-}" in -y|--yes) ASSUME_YES=1 ;; esac

MANIFEST="$HOME/.local/state/dotfiles/bootstrap.manifest"
DOTGIT="$HOME/.dotfiles"

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
ask()  { [ "$ASSUME_YES" = 1 ] && return 0; read -r -p "$1 [y/N] " a; [ "${a:-N}" = "y" ]; }
manifest_has() { [ -f "$MANIFEST" ] && grep -qxF "$1" "$MANIFEST"; }

echo "Teardown reverses bootstrap.sh. Pre-existing software is preserved"
echo "(decided by the manifest: $MANIFEST)."
[ -f "$MANIFEST" ] || warn "No manifest found — apt/Homebrew/OMZ/shell will NOT be touched (can't tell what pre-existed)."
ask "Proceed?" || { echo "aborted"; exit 0; }

# 1. Restore login shell FIRST (before anything that could remove zsh) -------
orig_shell="$(grep -E '^shell:' "$MANIFEST" 2>/dev/null | head -1 | cut -d: -f2-)"
if [ -n "$orig_shell" ] && [ "$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)" != "$orig_shell" ]; then
  info "Restoring login shell -> $orig_shell"
  chsh -s "$orig_shell" 2>/dev/null || warn "chsh failed; run manually: chsh -s $orig_shell"
fi

# 2. Tool data + cloned configs (always created by this setup) ---------------
for d in \
  "$HOME/.config/zsh/plugins" \
  "$HOME/.config/tmux/plugins" \
  "$HOME/.config/nvim" \
  "$HOME/.config/yazi" \
  "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim" \
  "$HOME/.local/share/fnm" \
  "$HOME/.local/share/atuin" \
  "$HOME/.gitconfig.local"; do
  [ -e "$d" ] && { info "rm $d"; rm -rf "$d"; }
done

# 3. SDKMAN (only if bootstrap installed it) ---------------------------------
if manifest_has "sdkman" && [ -d "$HOME/.sdkman" ]; then
  info "rm ~/.sdkman"; rm -rf "$HOME/.sdkman"
fi

# 4. Oh My Zsh (only if bootstrap installed it) ------------------------------
if manifest_has "omz" && [ -d "$HOME/.oh-my-zsh" ]; then
  info "rm ~/.oh-my-zsh"; rm -rf "$HOME/.oh-my-zsh"
fi

# 5. Homebrew (only if bootstrap installed it — else leave it + its formulae) -
if manifest_has "brew"; then
  for p in /home/linuxbrew/.linuxbrew /opt/homebrew /usr/local/Homebrew; do
    [ -x "$p/bin/brew" ] || continue
    info "Removing Homebrew + all its formulae at $p"
    sudo rm -rf "$p"
  done
  rm -rf "$HOME/.cache/Homebrew" "$HOME/.bundle"
elif have brew; then
  warn "Homebrew pre-existed — leaving it. To drop only this setup's formulae,"
  warn "review and run:  brew bundle --file ~/Brewfile cleanup"
fi

# 6. apt packages bootstrap added (and nothing else) -------------------------
apt_pkgs="$(grep -E '^apt:' "$MANIFEST" 2>/dev/null | cut -d: -f2- | tr '\n' ' ')"
if [ -n "${apt_pkgs// /}" ]; then
  info "apt packages bootstrap installed:$apt_pkgs"
  if ask "Purge them?"; then
    # shellcheck disable=SC2086
    sudo apt-get purge -y $apt_pkgs && sudo apt-get autoremove -y
  fi
fi

# 7. Optional: remove the dotfiles checkout itself ---------------------------
if [ -d "$DOTGIT" ] && ask "Also remove the dotfiles files + bare repo (~/.dotfiles)?"; then
  if git --git-dir="$DOTGIT" --work-tree="$HOME" rev-parse >/dev/null 2>&1; then
    git --git-dir="$DOTGIT" --work-tree="$HOME" ls-files -z \
      | while IFS= read -r -d '' f; do rm -f "$HOME/$f"; done
  fi
  rm -rf "$DOTGIT"
  if [ -d "$HOME/.dotfiles-backup" ]; then
    info "Restoring files the checkout had backed up (~/.dotfiles-backup)"
    cp -a "$HOME/.dotfiles-backup/." "$HOME/" 2>/dev/null || true
    rm -rf "$HOME/.dotfiles-backup"
  fi
fi

# 8. Remove the manifest itself ----------------------------------------------
rm -f "$MANIFEST"; rmdir "$(dirname "$MANIFEST")" 2>/dev/null || true

info "Teardown complete. Start a fresh login shell."
