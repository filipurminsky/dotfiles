#!/usr/bin/env bash
# Show GlobalProtect's state only. Other packet-tunnel apps also create a
# routable `utun` interface, so checking interfaces can produce false positives.
# PanGPS records the authoritative state transitions in its system log.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/hover.sh"

GP_LOG=/Library/Logs/PaloAltoNetworks/GlobalProtect/PanGPS.log
GP_STATE=$(awk '
  /Set state to Connected/                 { state = "Connected" }
  /Set state to Disconnected/              { state = "Disconnected" }
  /Set state to Restoring VPN Connection/  { state = "Restoring" }
  END { print state }
' "$GP_LOG" 2>/dev/null)

if [ "$GP_STATE" = "Connected" ]; then
  sketchybar --set "$NAME" icon.color=$GREEN icon.background.border_color=$GREEN     # green — tunnel up
elif [ "$GP_STATE" = "Restoring" ]; then
  sketchybar --set "$NAME" icon.color=$YELLOW icon.background.border_color=$YELLOW  # yellow — reconnecting
else
  sketchybar --set "$NAME" icon.color=$OVERLAY icon.background.border_color=$OVERLAY # grey — no tunnel
fi
