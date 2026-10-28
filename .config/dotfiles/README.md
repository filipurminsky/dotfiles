# dotfiles

My **macOS / Linux** shell/tool configuration, tracked as a **bare git repo**
(git db in `~/.dotfiles`, work-tree is `$HOME`) so files are version-controlled
in place — no symlinks. Works identically on macOS and Ubuntu (via Linuxbrew).

## What's tracked here
- `.zshrc`, `.zprofile`, and `.config/zsh/*.zsh` (exports, aliases, functions, tools)
- `.gitconfig` (identity is in the untracked `~/.gitconfig.local`)
- `.config/tmux/tmux.conf`
- `.config/atuin/config.toml`
- `.config/git/ignore` (global excludes: `.DS_Store` and friends, every repo)
- `.config/btop/` (`btop.conf` + a hand-built `catppuccin_mocha.theme`, since
  the Homebrew formula ships no Catppuccin variant)
- `.config/lazygit/config.yml`
- Other tool configs: `ghostty`, `karabiner`, `zathura`, `aerc` (minus
  accounts), `gh` (`config.yml` only), `glow`, `lazydocker`, `sqlit` (settings
  and keymap, not connections)
- Claude Code: `.claude/settings.json`, `keybindings.json`, `statusline-command.sh`
- Codex: `.config/dotfiles/codex-config.toml` (portable preferences)
- Hand-written scripts in `.local/bin/`
- `Brewfile` (cross-platform formulae) + `Brewfile.macos` (macOS-only casks/fonts)
- `.config/dotfiles/` (this README + `bootstrap.sh`)
- macOS desktop: `.config/aerospace/` (tiling WM), `.config/sketchybar/` (bar +
  plugins), `.config/borders/` — see the note below on the one build artefact

## Deliberately NOT tracked
- `~/.ssh/` — excluded wholesale in `~/.gitignore`. This repo is public and
  `status.showUntrackedFiles no` hides mistakes, so a stray `dotfiles add -A`
  from `$HOME` is the one accident that must never reach a remote.
- Credentials and machine state: gh/Copilot/Snyk tokens, fabric `.env`,
  sqlit connections and saved queries, FileZilla, Claude Code session data.
  See `~/.gitignore` for the full list — and **Migrate to a new computer**
  below for how the ones you need get moved by hand.
- `.config/tmuxp/` — session templates whose `start_directory` paths name
  employer repos. In `.dotfiles/info/exclude` (repo-local) rather than
  `~/.gitignore`, because here the pattern itself is what leaks.

## What lives in its own repo (cloned by bootstrap)
- Neovim → [`nvim-config`](https://github.com/filipurminsky/nvim-config) → `~/.config/nvim`
- Yazi   → [`yazi-config`](https://github.com/filipurminsky/yazi-config) (public) → `~/.config/yazi`
- zsh plugins / TPM / yazi packages → installed, not vendored

## Migrate to a new computer
The repos carry everything shareable. Secrets, work-specific files and shell
history travel separately, in an encrypted disk image you make on the old
machine.

### 1. On the old machine
Make sure nothing is left only locally:
```sh
dotfiles status                       # commit + push anything listed
git -C ~/.config/nvim status
git -C ~/.config/yazi status
dotfiles push; git -C ~/.config/nvim push; git -C ~/.config/yazi push
```

Flush shell history to atuin and save its encryption key — history is
encrypted client-side, so without the key the synced copy is unreadable:
```sh
atuin sync
atuin key        # store the printed words in your password manager
```

Pack the private files into an AES-256 encrypted image (prompts for a
password). Paths that don't exist are skipped:
```sh
cd ~
paths=(
  .ssh .gnupg .aws .kube          # keys, cloud and cluster credentials
  .gitconfig.local                # git identity
  .zsh_history                    # zsh-autosuggestions reads this, not atuin
  .local/share/atuin/key          # atuin encryption key (also in password manager)
  .config/aerc                    # incl. untracked account and credential files
  .config/tmuxp                   # session templates (private paths)
  .config/sqlit/connections.json .config/sqlit/queries
  .config/fabric/.env             # API keys
  .config/configstore             # Snyk token
  .claude/automode.private.json   # work-specific auto-mode rules
)
stage=$(mktemp -d)
for p in "${paths[@]}"; do [ -e "$p" ] && rsync -aR "$p" "$stage/"; done
hdiutil create -encryption AES-256 -srcfolder "$stage" -volname migrate ~/Desktop/migrate.dmg
rm -rf "$stage"
```
Move `migrate.dmg` over by AirDrop or a USB stick — not a cloud folder.

### 2. On the new machine
1. Install the dotfiles and run `bootstrap.sh` — see **Set up a new machine**
   below.
2. Restore the private files, then tighten permissions:
   ```sh
   open ~/Downloads/migrate.dmg          # asks for the image password
   rsync -a /Volumes/migrate/ ~/
   chmod 700 ~/.ssh ~/.gnupg; chmod 600 ~/.ssh/id_*
   gpgconf --kill gpg-agent              # pick up the copied keyring
   hdiutil detach /Volumes/migrate && rm ~/Downloads/migrate.dmg
   ```
3. Merge `~/.claude/automode.private.json` back into `~/.claude/settings.json`
   (it is the `autoMode` key, kept out of this public repo).
4. Shell history:
   ```sh
   atuin login -u filipurminsky          # password + key from step 1
   atuin sync
   ```
5. Sign in again where a token was deliberately left behind: `gh auth login`,
   GitHub Copilot (`:Copilot auth` in Neovim), `codex login`, Claude Code.
6. Re-add the aerc Gmail app password to the keychain (see **Notes** below).
7. Grant permissions when macOS asks: **Accessibility** for AeroSpace and
   Karabiner-Elements (plus its driver extension), **Location** for
   WiFiSSIDHelper (Wi-Fi name in the bar), **Bluetooth** for btbattery.
8. Open tmux and press `prefix + I` if the plugins didn't install.

Not covered by any of this: app data with its own sync (browsers, Obsidian
vaults in iCloud, Teams/Outlook), Docker images, and SDKMAN JDKs — reinstall
or re-sign-in as needed.

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
Zsh, login shell, cloned configs, and tool data are preserved**. For manifests created
by older versions, ownership is unknown, so teardown leaves those paths in place; the
dotfiles checkout itself is removed on confirm.

## Day-to-day
Use the `dotfiles` alias like `git`:
```sh
dotfiles status
dotfiles add ~/.config/tmux/tmux.conf
dotfiles commit -m "tweak tmux"
dotfiles push
```

## Notes
- Codex: merge `.config/dotfiles/codex-config.toml` into `~/.codex/config.toml`
  to enable Vim mode by default. If `[tui]` already exists, add
  `vim_mode_default = true` to that section. Use `/vim` to toggle it in the
  current session. Keep `~/.codex/` local: it contains credentials, sessions,
  and project trust settings.
- `~/.gitconfig.local` holds your git identity and is **never** tracked (keeps
  email out of this public repo). `bootstrap.sh` creates it on a new machine.
- tmux plugins: after first launch, press `prefix + I` if `bootstrap.sh`'s TPM
  install didn't run.
- atuin history: synced, end-to-end encrypted. On a new machine run
  `atuin login` + `atuin sync` rather than `atuin import auto` — the key comes
  from `atuin key` on the old one (see **Migrate to a new computer**).
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
  `brew services`. AeroSpace sets `start-at-login`; its startup command runs
  `~/.config/dotfiles/desktop-services.sh`. That idempotent installer registers
  launchd supervisors for SketchyBar, borders, and the microphone watcher.
  Existing processes keep running; the supervisor starts their replacement
  when they exit. Templates live in `.config/dotfiles/launchd/`.
  AeroSpace needs **Accessibility** permission (System Settings >
  Privacy & Security) before it can manage windows.
- sketchybar has three build artefacts, all compiled by `bootstrap.sh` from
  tracked Swift sources: `bin/micstatus` (microphone-in-use watcher, plain
  build), `wifi-ssid-helper/WiFiSSIDHelper.app` (an app bundle, because the
  Location permission macOS requires for reading the SSID attaches to a bundle
  ID; ad-hoc signed, started by a `__HOME__`-templated launch agent), and
  `bin/btbattery`: the Swift source is
  tracked, the compiled binary is gitignored, and `bootstrap.sh` builds it with
  `swiftc -sectcreate` to embed `btbattery-Info.plist`. That embedding is
  required — TCC reads the Bluetooth usage description from the binary's own
  `__info_plist` section, and CoreBluetooth aborts silently without it. A
  launchd timer (`.config/sketchybar/launchd/`, installed to
  `~/Library/LaunchAgents` with `__HOME__` substituted) runs the poll wrapper,
  because a plugin spawned by sketchybar inherits sketchybar's TCC context and
  gets denied.
- tmux restores Neovim through `.config/tmux/nvim-restore.sh`, which opts into
  LazyVim Persistence's project/branch session. Neovim checkpoints that session
  every minute and on focus/buffer changes while persistence is enabled;
  `<leader>qd` still disables saving. Regular launches do not auto-restore.
- Neovim leaves the shell's `JAVA_HOME` alone. On macOS, jdtls selects Java 21+
  using `java_home`; Groovy alone uses the installed Temurin 19 runtime.
  To rebuild Mason's installed Groovy server with its compatible Gradle JVM,
  run `build-groovy-language-server`. This scopes Java 19 to that build process.
- SketchyBar expires keyboard readings after 15 minutes and SSID readings
  after one minute. Invalid weather responses preserve the last valid cache.
  The microphone helper uses CoreAudio process input activity (macOS 14.2+),
  avoiding false microphone indications from headset playback.
