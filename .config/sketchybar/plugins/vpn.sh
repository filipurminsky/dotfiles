#!/usr/bin/env bash
# Show GlobalProtect's state only. Other packet-tunnel apps also create a
# routable `utun` interface, so checking interfaces can produce false positives.
# Only new log data is read after the first bounded pass. Transitions from
# older daemon instances are ignored; a stopped daemon cannot remain green.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/hover.sh"

GP_STATE=$("$CONFIG_DIR/bin/vpn-state.py" 2>/dev/null)

if [ "$GP_STATE" = "Connected" ]; then
  sketchybar --set "$NAME" icon.color="$GREEN" icon.background.border_color="$GREEN"     # green — tunnel up
elif [ "$GP_STATE" = "Restoring" ]; then
  sketchybar --set "$NAME" icon.color="$YELLOW" icon.background.border_color="$YELLOW"  # yellow — reconnecting
else
  sketchybar --set "$NAME" icon.color="$OVERLAY" icon.background.border_color="$OVERLAY" # grey — no tunnel
fi
