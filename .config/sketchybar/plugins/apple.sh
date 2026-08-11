#!/usr/bin/env bash
# Close the popup when the pointer leaves the bar entirely, so it can't get
# stuck open. Not in the original — its click_script only toggles.

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set apple.logo popup.drawing=off
fi
