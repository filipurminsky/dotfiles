#!/usr/bin/env bash
# Keychron K3 Max battery. The reading itself is taken by the launchd agent
# local.sketchybar.btbattery (see bin/btbattery-poll.sh for why it cannot be
# taken here); this only renders whatever the agent last cached.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/hover.sh"

CACHE="$HOME/.cache/sketchybar/keyboard-battery"
[ -r "$CACHE" ] || exit 0

read -r CODE PERCENT < "$CACHE"

case "$CODE" in
  0) ;;                                              # got a reading
  2) sketchybar --set "$NAME" drawing=off; exit 0 ;;  # keyboard off or away
  *) exit 0 ;;                                       # transient — leave as-is
esac

case "$PERCENT" in
  100|9[0-9]|8[0-9]|7[0-9]|6[0-9]|5[0-9]|4[0-9]|3[0-9]) COLOR=$SAPPHIRE ;;
  2[0-9]|1[0-9])                                        COLOR=$YELLOW ;;
  *)                                                    COLOR=$RED ;;
esac

sketchybar --set "$NAME" \
  drawing=on \
  icon="󰌌" \
  icon.color="$COLOR" \
  label="${PERCENT}%"
