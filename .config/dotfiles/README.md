# dotfiles

My **macOS / Linux** shell/tool configuration, tracked as a **bare git repo**
(git db in `~/.dotfiles`, work-tree is `$HOME`) so files are version-controlled
in place — no symlinks. Works identically on macOS and Ubuntu (via Linuxbrew).

## What's tracked here
- `.zshrc`, `.zprofile`, and `.config/zsh/*.zsh` (exports, aliases, functions, tools)
- `.gitconfig` (identity is in the untracked `~/.gitconfig.local`)
- `.config/tmux/tmux.conf`
- `.config/atuin/config.toml`
- `Brewfile` (cross-platform formulae) + `Brewfile.macos` (macOS-only casks/fonts)
- `.config/dotfiles/` (this README + `bootstrap.sh`)
- macOS desktop: `.config/aerospace/` (tiling WM), `.config/sketchybar/` (bar +
  plugins), `.config/borders/` — see the note below on the one build artefact

## What lives in its own repo (cloned by bootstrap)
- Neovim → [`nvim-config`](https://github.com/filipurminsky/nvim-config) → `~/.config/nvim`
- Yazi   → [`yazi-config`](https://github.com/filipurminsky/yazi-config) (public) → `~/.config/yazi`
- zsh plugins / TPM / yazi packages → installed, not vendored

## Set up a new machine
`bootstrap.sh` auto-detects macOS vs Linux — you only need `git` + the bare repo first.

**macOS** — Xcode CLT provides git:
```sh
xcode-select --install
```
**Ubuntu/Linux** — install git:
```sh
sudo apt-get update && sudo apt-get install -y git
```

Then, on **both**:
```sh
# Clone the bare repo
git clone --bare https://github.com/filipurminsky/dotfiles.git "$HOME/.dotfiles"
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# Check out the files into $HOME
dotfiles checkout
#   If it errors about existing files (e.g. a default ~/.zshrc), back them up:
#     dotfiles checkout 2>&1 | grep -E '^\s' | awk '{print $1}' | \
#       xargs -I{} sh -c 'mkdir -p ~/.dotfiles-backup/$(dirname {}); mv {} ~/.dotfiles-backup/{}'
#   then re-run: dotfiles checkout
dotfiles config status.showUntrackedFiles no

# Run the installer. It auto-detects the OS:
#   Linux  -> apt prereqs -> Linuxbrew -> brew bundle (Brewfile)
#   macOS  -> Homebrew -> brew bundle (Brewfile + Brewfile.macos casks/fonts)
# then OMZ, zsh plugins, nvim/yazi, TPM, fnm, Sqlit (with MySQL support),
# optional zsh login shell, git identity, and on macOS the desktop stack
# (btbattery build + launchd timer, first AeroSpace launch).
~/.config/dotfiles/bootstrap.sh
```

### Light mode
For lightweight boxes (servers, containers, throwaway VMs) where you only want
the editing/navigation core:
```sh
~/.config/dotfiles/bootstrap.sh --mode=light
```
Installs **zsh + plugins, tmux + plugins, neovim + plugins, yazi, ripgrep, fzf,
zoxide, fd** — and skips the full Brewfile, GUI casks/fonts, Node (fnm), and
SDKMAN. neovim plugins/LSPs install on first launch. Footprint: ~0.4 GB after
bootstrap, growing as nvim's Mason populates on use.

> On a headless remote (Ubuntu server), GUI apps/fonts are skipped — Nerd Font
> glyphs render in your **local** terminal over SSH, so the prompt/icons still work.

## Tear down a box
Reverse everything `bootstrap.sh` installed and leave the machine as it was:
```sh
~/.config/dotfiles/teardown.sh        # prompts per step;  -y for unattended
```
It reads a manifest `bootstrap.sh` writes (`~/.local/state/dotfiles/bootstrap.manifest`)
and only removes what *it* installed — **pre-existing apt packages, Homebrew, Oh My
Zsh, and your login shell are preserved**. Tool data and cloned configs (nvim/yazi,
plugins, fnm) are always removed; the dotfiles checkout itself is removed on confirm.

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
- aerc (email): `aerc.conf` + `binds.conf` are tracked; `~/.config/aerc/accounts.conf`
  is **never** tracked (account details out of this public repo). On a new machine,
  recreate it and store the Gmail app password in the keychain — aerc reads it via
  `source-cred-cmd`, no plaintext on disk:
  ```sh
  security add-generic-password -U -a f.urminsky@gmail.com -s aerc-gmail -w 'APP_PW'
  ```
  On Linux there's no `security`; swap the `*-cred-cmd` lines to a local secret
  store (e.g. `pass show aerc-gmail`).
- macOS desktop (aerospace + sketchybar + borders): none of the three uses
  `brew services`. `aerospace.toml` sets `start-at-login` and its
  `after-startup-command` execs borders and sketchybar, so AeroSpace brings up
  the whole bar. AeroSpace needs **Accessibility** permission (System Settings >
  Privacy & Security) before it can manage windows.
- `sketchybar/bin/btbattery` is the one build artefact: the Swift source is
  tracked, the compiled binary is gitignored, and `bootstrap.sh` builds it with
  `swiftc -sectcreate` to embed `btbattery-Info.plist`. That embedding is
  required — TCC reads the Bluetooth usage description from the binary's own
  `__info_plist` section, and CoreBluetooth aborts silently without it. A
  launchd timer (`.config/sketchybar/launchd/`, installed to
  `~/Library/LaunchAgents` with `__HOME__` substituted) runs the poll wrapper,
  because a plugin spawned by sketchybar inherits sketchybar's TCC context and
  gets denied.
