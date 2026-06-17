# dotfiles

My macOS shell/tool configuration, tracked as a **bare git repo** (git db in
`~/.dotfiles`, work-tree is `$HOME`) so files are version-controlled in place —
no symlinks.

## What's tracked here
- `.zshrc` and `.config/zsh/*.zsh` (exports, aliases, functions, tools)
- `.gitconfig` (identity is in the untracked `~/.gitconfig.local`)
- `.config/tmux/tmux.conf`
- `.config/atuin/config.toml`
- `Brewfile` (all Homebrew packages)
- `.config/dotfiles/` (this README + `bootstrap.sh`)

## What lives in its own repo (cloned by bootstrap)
- Neovim → [`nvim-config`](https://github.com/filipurminsky/nvim-config) → `~/.config/nvim`
- Yazi   → `yazi-config` (private) → `~/.config/yazi`
- zsh plugins / TPM / yazi packages → installed, not vendored

## Set up a new machine
```sh
# 1. Xcode CLT + Homebrew
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone the bare repo
git clone --bare https://github.com/filipurminsky/dotfiles.git "$HOME/.dotfiles"
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# 3. Check out the files into $HOME
dotfiles checkout
#    If it errors about existing files (e.g. a default ~/.zshrc), back them up:
#      dotfiles checkout 2>&1 | grep -E '^\s' | awk '{print $1}' | \
#        xargs -I{} sh -c 'mkdir -p ~/.dotfiles-backup/$(dirname {}); mv {} ~/.dotfiles-backup/{}'
#    then re-run: dotfiles checkout
dotfiles config status.showUntrackedFiles no

# 4. Run the installer (brew bundle, OMZ, plugins, nvim/yazi, TPM, fnm, identity)
~/.config/dotfiles/bootstrap.sh
```

## Day-to-day
Use the `dotfiles` alias like `git`:
```sh
dotfiles status
dotfiles add ~/.config/tmux/tmux.conf
dotfiles commit -m "tweak tmux"
dotfiles push
```

## Notes
- `~/.gitconfig.local` holds your git identity and is **never** tracked (keeps
  email out of this public repo). `bootstrap.sh` creates it on a new machine.
- tmux plugins: after first launch, press `prefix + I` if `bootstrap.sh`'s TPM
  install didn't run.
- atuin history: `atuin import auto`, then `atuin login` for cross-machine sync.
