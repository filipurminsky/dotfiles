#!/usr/bin/env bash
# $INFO is the volume percentage on a volume_change event.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/hover.sh"

VOL="$INFO"
if [ -z "$VOL" ]; then
  VOL=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)
fi
MUTED=$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)
[ -z "$VOL" ] && exit 0

if [ "$MUTED" = "true" ] || [ "$VOL" -eq 0 ]; then
  ICON="󰝟"; COLOR=$OVERLAY
elif [ "$VOL" -gt 60 ]; then
  ICON="󰕾"; COLOR=$PINK
elif [ "$VOL" -gt 20 ]; then
  ICON="󰖀"; COLOR=$PINK
else
  ICON="󰕿"; COLOR=$PINK
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${VOL}%"
