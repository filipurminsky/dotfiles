#!/bin/sh
# Install/start the desktop supervisors without restarting existing services.
set -eu
[ "$(uname -s)" = Darwin ] || exit 0
root="$HOME/.config/dotfiles"
agents="$HOME/Library/LaunchAgents"
domain="gui/$(id -u)"
mkdir -p "$agents"
manifest="$HOME/.local/state/dotfiles/bootstrap.manifest"
mkdir -p "${manifest%/*}"
for service in sketchybar borders micstatus; do
  label="com.filipurminsky.desktop.$service"
  target="$agents/$label.plist"
  tmp=$(mktemp "$agents/.$label.XXXXXX")
  trap 'rm -f "$tmp"' EXIT
  # Home paths are XML text; escape replacement characters for sed as well.
  escaped=$(printf '%s' "$HOME" | sed 's/\&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/[\\&|]/\\&/g')
  sed "s|__HOME__|$escaped|g" "$root/launchd/$label.plist" > "$tmp"
  if ! cmp -s "$tmp" "$target"; then
    chmod 644 "$tmp"
    mv "$tmp" "$target"
  else
    rm -f "$tmp"
  fi
  if ! launchctl print "$domain/$label" >/dev/null 2>&1; then
    launchctl bootstrap "$domain" "$target"
  fi
  grep -qxF "launchagent:$label" "$manifest" 2>/dev/null || printf '%s\n' "launchagent:$label" >> "$manifest"
done
