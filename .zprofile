# ~/.zprofile — login-shell setup (tracked in dotfiles).
#
# Put Homebrew on PATH portably. macOS gets brew via /etc/paths.d, but Linux
# (Linuxbrew) has no such mechanism, so we eval `brew shellenv` for whichever
# prefix exists. Harmless re-affirm on macOS; essential on Linux.
for _b in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew "$HOME/.linuxbrew"; do
  if [[ -x "$_b/bin/brew" ]]; then
    eval "$("$_b/bin/brew" shellenv)"
    break
  fi
done
unset _b
