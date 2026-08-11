#!/usr/bin/env bash
# Shows time remaining rather than percentage. pmset reports time-to-empty on
# battery and time-to-full while charging; it reports 0:00 or "(no estimate)"
# for a while after a power source change, so fall back to a dash.

source "$CONFIG_DIR/plugins/colors.sh"

BATT=$(pmset -g batt)
PERCENT=$(echo "$BATT" | grep -Eo '[0-9]+%' | tr -d '%')
TIME=$(echo "$BATT" | grep -Eo '[0-9]+:[0-9]{2}' | head -1)
CHARGING=$(echo "$BATT" | grep -c 'AC Power')

[ -z "$PERCENT" ] && exit 0

if [ "$CHARGING" -ne 0 ]; then
  ICON="󰂄"
  COLOR=$GREEN
else
  case "${PERCENT}" in
    9[0-9]|100) ICON="󰁹"; COLOR=$TEXT ;;
    [6-8][0-9]) ICON="󰂁"; COLOR=$TEXT ;;
    [3-5][0-9]) ICON="󰁽"; COLOR=$YELLOW ;;
    [1-2][0-9]) ICON="󰁻"; COLOR=$PEACH ;;
    *)          ICON="󰁺"; COLOR=$RED ;;
  esac
fi

if [ "$CHARGING" -ne 0 ] && [ "$PERCENT" -ge 100 ]; then
  LABEL="full"
elif [ -n "$TIME" ] && [ "$TIME" != "0:00" ]; then
  LABEL="$TIME"
else
  LABEL="—"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL"
