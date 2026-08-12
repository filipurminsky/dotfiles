#!/usr/bin/env bash
# Zscaler and GlobalProtect are packet-tunnel apps: they don't register with
# `scutil --nc list`, and their daemons run whether or not a tunnel is up, so
# neither the service list nor pgrep tells you anything useful.
#
# What does: a utun interface carrying a routable IPv4. macOS keeps several
# utun devices up at all times for its own services, but they hold no address
# (or only a 169.254 link-local) unless a tunnel is actually established.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/hover.sh"

IFACE=$(ifconfig 2>/dev/null | awk '
  /^[a-z0-9]+:/       { i = ""; if ($1 ~ /^utun/) i = substr($1, 1, length($1) - 1) }
  /^[[:space:]]*inet / { if (i != "" && $2 !~ /^169\.254\./) { print i; exit } }')

# Connected is connected. GlobalProtect is split-tunnel here by design — it
# installs ~150 specific routes and leaves the default on en0 — so flagging
# that as a warning colour would mean a permanent yellow whenever the VPN is
# up, which is exactly the state that should look fine.

if [ -n "$IFACE" ]; then
  sketchybar --set "$NAME" icon.color=$GREEN icon.background.border_color=$GREEN     # green — tunnel up
else
  sketchybar --set "$NAME" icon.color=$OVERLAY icon.background.border_color=$OVERLAY # grey — no tunnel
fi
