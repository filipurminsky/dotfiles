#!/usr/bin/env bash
# Status light only. The SSID is unavailable to a CLI process on macOS 26
# (Location Services gated), and the local IP isn't wanted on screen.
#
# Check the physical interface first: under a full-tunnel VPN the default
# route moves onto a utun device, which a route-based check misreads as
# "wired" while actually on Wi-Fi. en0 is the built-in Wi-Fi here.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/hover.sh"

if [ -n "$(ipconfig getifaddr en0 2>/dev/null)" ]; then
  sketchybar --set "$NAME" icon="󰖩" icon.color=$BLUE
  exit 0
fi

# No address on Wi-Fi — anything still holding a default route is wired,
# docked, or tethered; otherwise offline.
IFACE=$(route get default 2>/dev/null | awk '/interface:/ {print $2}')

if [ -n "$IFACE" ]; then
  sketchybar --set "$NAME" icon="󰈀" icon.color=$BLUE
else
  sketchybar --set "$NAME" icon="󰖪" icon.color=$RED
fi
