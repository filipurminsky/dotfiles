#!/usr/bin/env bash
# Bootstrap a fresh macOS or Ubuntu/Linux machine from the dotfiles repo.
#
# Run AFTER the bare dotfiles repo has been checked out into $HOME
# (see README.md for the checkout steps). Idempotent: safe to re-run.
set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.config/zsh}"
GH_USER="filipurminsky"
OS="$(uname -s)"   # Darwin | Linux

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Manifest of what THIS run installs, so teardown.sh reverses only these and
# leaves anything that pre-existed untouched. One fact per line, deduped.
MANIFEST="$HOME/.local/state/dotfiles/bootstrap.manifest"
mkdir -p "$(dirname "$MANIFEST")"
record() { grep -qxF "$1" "$MANIFEST" 2>/dev/null || echo "$1" >> "$MANIFEST"; }

# 1. Homebrew (+ Linux build prerequisites) ---------------------------------
if [ "$OS" = "Linux" ]; then
  info "Installing Linuxbrew prerequisites via apt"
  sudo apt-get update
  for p in build-essential procps curl file git; do
    dpkg -s "$p" >/dev/null 2>&1 || record "apt:$p"   # only packages we add
  done
  sudo apt-get install -y build-essential procps curl file git
fi
if ! have brew; then
  record "brew"
  info "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Put brew on PATH for the rest of this script (prefix differs by OS/arch).
for _b in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew "$HOME/.linuxbrew"; do
  [ -x "$_b/bin/brew" ] && eval "$("$_b/bin/brew" shellenv)" && break
done

# 2. Brew packages ----------------------------------------------------------
if [ -f "$HOME/Brewfile" ]; then
  info "Installing cross-platform packages from ~/Brewfile"
  brew bundle --file="$HOME/Brewfile"
fi
if [ "$OS" = "Darwin" ] && [ -f "$HOME/Brewfile.macos" ]; then
  info "Installing macOS-only packages from ~/Brewfile.macos"
  brew bundle --file="$HOME/Brewfile.macos"
fi

# 3. Oh My Zsh --------------------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  record "omz"
  info "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 4. Custom zsh plugins (live in $ZSH_CUSTOM/plugins, cloned not vendored) ---
info "Installing zsh plugins into $ZSH_CUSTOM/plugins"
mkdir -p "$ZSH_CUSTOM/plugins"
clone_plugin() {  # <repo-url> <dir>
  local dir="$ZSH_CUSTOM/plugins/$2"
  [ -d "$dir" ] || git clone --depth=1 "$1" "$dir"
}
clone_plugin https://github.com/zsh-users/zsh-autosuggestions      zsh-autosuggestions
clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting  zsh-syntax-highlighting
clone_plugin https://github.com/jeffreytse/zsh-vi-mode             zsh-vi-mode

# 5. Repo clone helper: prefer anonymous HTTPS (works for public repos with no
#    auth prompt, so unattended runs don't block). Fall back to gh only if the
#    public clone fails (i.e. the repo is private), authenticating then.
clone_repo() {  # <repo> <target>
  [ -d "$2/.git" ] && { info "$2 already present"; return; }
  info "Cloning $1 -> $2"
  git clone "https://github.com/$GH_USER/$1.git" "$2" 2>/dev/null && return
  if have gh; then
    info "Public clone failed (private repo?) — authenticating with gh"
    gh auth status >/dev/null 2>&1 || gh auth login
    gh repo clone "$GH_USER/$1" "$2"
  fi
}

# 6. Neovim + yazi configs (their own repos) --------------------------------
clone_repo nvim-config "$HOME/.config/nvim"
clone_repo yazi-config "$HOME/.config/yazi"
if have ya; then info "Installing yazi packages"; ya pkg install || true; fi

# 7. tmux: TPM + plugins ----------------------------------------------------
TPM="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM" ]; then
  info "Installing TPM"
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM"
fi
info "Installing tmux plugins"
# Run inside a throwaway detached server so tmux.conf (and TPM) is sourced,
# otherwise install_plugins errors with "TMUX_PLUGIN_MANAGER_PATH unset" headless.
tmux new-session -d -s __tpm_install 2>/dev/null || true
"$TPM/bin/install_plugins" >/dev/null 2>&1 || true
tmux kill-session -t __tpm_install 2>/dev/null || true

# 8. Node versions via fnm --------------------------------------------------
if have fnm; then
  info "Installing Node versions via fnm"
  eval "$(fnm env)"
  fnm install 20.20.2 || true
  fnm install 24.15.0 || true
  fnm default 24.15.0 || true
fi

# 9. SDKMAN (optional) ------------------------------------------------------
if [ ! -d "$HOME/.sdkman" ]; then
  read -r -p "Install SDKMAN (Java/Gradle/Maven)? [y/N] " a
  if [ "${a:-N}" = "y" ]; then record "sdkman"; curl -s "https://get.sdkman.io" | bash; fi
fi

# 10. Default login shell -> zsh (servers default to bash) ------------------
ZSH_BIN="$(command -v zsh || true)"
if [ -n "$ZSH_BIN" ] && [ "${SHELL:-}" != "$ZSH_BIN" ]; then
  read -r -p "Set zsh ($ZSH_BIN) as your login shell? [y/N] " a
  if [ "${a:-N}" = "y" ]; then
    record "shell:$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "${SHELL:-}")"
    grep -qx "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$ZSH_BIN"
  fi
fi

# 11. Machine-local git identity -------------------------------------------
if [ ! -f "$HOME/.gitconfig.local" ]; then
  info "Creating ~/.gitconfig.local (git identity — not tracked)"
  read -r -p "  git user.name:  " name
  read -r -p "  git user.email: " email
  printf '[user]\n\tname = %s\n\temail = %s\n' "$name" "$email" > "$HOME/.gitconfig.local"
fi

info "Done. Open a new shell. Optional: 'atuin import auto' (history), 'atuin login' (sync)."
