#!/usr/bin/env bash
# Hover pill for workspace items. Their background is also the blue focus
# pill (spaces.sh toggles background.drawing, the colour is set here), so on
# exit repaint from the real focus state rather than assuming the hover pill
# is still ours — the workspace may have been clicked mid-hover.

source "$CONFIG_DIR/plugins/colors.sh"

SID="${NAME#space.}"
FOCUSED=$(/opt/homebrew/bin/aerospace list-workspaces --focused 2>/dev/null)

case "$SENDER" in
  mouse.entered)
    [ "$SID" = "$FOCUSED" ] && exit 0   # already wearing the blue pill
    sketchybar --set "$NAME" background.drawing=on background.color=$LINE
    ;;
  mouse.exited)
    if [ "$SID" = "$FOCUSED" ]; then
      sketchybar --set "$NAME" background.color=$BLUE background.drawing=on
    else
      # order matters: setting background.color implicitly re-enables
      # background.drawing, so drawing=off must come after it
      sketchybar --set "$NAME" background.color=$BLUE background.drawing=off
    fi
    ;;
esac
