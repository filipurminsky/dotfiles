#!/usr/bin/env bash
# Append one workspace's creation arguments to the caller's args array.
add_workspace() {
  local sid="$1" quoted
  printf -v quoted '%q' "$sid"
  args+=(--add item "space.$sid" left
    --subscribe "space.$sid" mouse.entered mouse.exited
    --set "space.$sid"
      script="$CONFIG_DIR/plugins/space_hover.sh"
      icon="$sid" icon.font="JetBrainsMono NFM:Bold:13.0"
      icon.padding_left=9 icon.padding_right=5
      label.font="sketchybar-app-font:Regular:15.0" label.padding_right=9
      label.drawing=off background.color="$BLUE" background.drawing=off
      drawing=off click_script="aerospace workspace $quoted")
}
