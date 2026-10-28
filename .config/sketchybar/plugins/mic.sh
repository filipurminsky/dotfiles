#!/usr/bin/env bash
# Microphone-in-use indicator — the bar's stand-in for macOS's orange dot,
# which the system draws over the top-right corner of the bar and which no
# API can move or suppress.
#
# bin/micstatus does the CoreAudio read; the resident `micstatus --watch`
# started by sketchybarrc fires mic_change the moment recording starts or
# stops, so this normally runs twice per call rather than on a timer.
# Draws only while something is capturing, the same way the dot behaves.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/hover.sh"

STATE=$("$CONFIG_DIR/bin/micstatus" 2>/dev/null) || exit 0

if [ "$STATE" = "on" ]; then
  sketchybar --set "$NAME" drawing=on
else
  sketchybar --set "$NAME" drawing=off
fi
