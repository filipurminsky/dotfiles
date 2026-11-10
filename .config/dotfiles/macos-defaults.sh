#!/usr/bin/env bash
# macOS system preferences this setup relies on, captured from the working
# machine. Only values that differ from a fresh macOS install are listed.
# Idempotent: re-running rewrites the same values. Called by bootstrap.sh
# (full mode, Darwin); also safe to run by hand. Some take effect only after
# logging out (input sources, menu bar).
set -euo pipefail
[ "$(uname -s)" = Darwin ] || { echo "macos-defaults.sh: not macOS, skipping"; exit 0; }

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }

info "Appearance and text input"
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# SketchyBar replaces the menu bar, so the native one stays hidden.
info "Menu bar (hidden — SketchyBar replaces it)"
defaults write NSGlobalDomain _HIHideMenuBar -bool true

info "Dock and Spaces"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 44
# AeroSpace needs Spaces in a fixed order; macOS must not reorder them by use.
defaults write com.apple.dock mru-spaces -bool false
# Bottom-right hot corner: Quick Note (14), no modifier.
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0

info "Finder"
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv   # list view

info "Window tiling (AeroSpace manages gaps)"
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

# Keyboard layouts: ABC (US) is there by default; add Slovak QWERTY if missing.
info "Input sources (ABC + Slovak-QWERTY)"
if ! defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null \
    | grep -q '"KeyboardLayout Name" = "Slovak-QWERTY"'; then
  defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add \
    '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>30779</integer><key>KeyboardLayout Name</key><string>Slovak-QWERTY</string></dict>'
fi

# Apply what can be applied without logging out.
killall Dock Finder SystemUIServer 2>/dev/null || true
info "macOS defaults applied (log out and back in for input sources/menu bar)"
