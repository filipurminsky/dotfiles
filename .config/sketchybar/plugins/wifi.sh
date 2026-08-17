#!/usr/bin/env bash
# The SSID comes from WiFiSSIDHelper, a native app with Location Services
# permission. SketchyBar itself only reads its cache so it stays lightweight.
#
# Check the physical interface first: under a full-tunnel VPN the default
# route moves onto a utun device, which a route-based check misreads as
# "wired" while actually on Wi-Fi. en0 is the built-in Wi-Fi here.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/hover.sh"

SSID_CACHE="$HOME/.cache/sketchybar/wifi-ssid"
SSID=""
if [ -r "$SSID_CACHE" ]; then
  SSID=$(tr -d '\r\n' < "$SSID_CACHE" | cut -c1-32)
fi

if [ -n "$(ipconfig getifaddr en0 2>/dev/null)" ]; then
  if [ -n "$SSID" ]; then
    sketchybar --set "$NAME" icon="󰖩" icon.color=$BLUE label="$SSID" label.drawing=on
  else
    sketchybar --set "$NAME" icon="󰖩" icon.color=$BLUE label.drawing=off
  fi
  exit 0
fi

# No address on Wi-Fi — anything still holding a default route is wired,
# docked, or tethered; otherwise offline.
IFACE=$(route get default 2>/dev/null | awk '/interface:/ {print $2}')

if [ -n "$IFACE" ]; then
  sketchybar --set "$NAME" icon="󰈀" icon.color=$BLUE label.drawing=off
else
  sketchybar --set "$NAME" icon="󰖪" icon.color=$RED label.drawing=off
fi
