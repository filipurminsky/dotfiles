#!/usr/bin/env bash
# Single driver for every workspace item.
#
# Runs on aerospace_workspace_change and front_app_switched, plus a slow poll
# for background windows that open or close without moving focus (AeroSpace
# only notifies on workspace change). Batches all nine items into one
# sketchybar call, and the whole pass costs three spawns: aerospace twice,
# awk once.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/icon_map.sh"

AEROSPACE=/opt/homebrew/bin/aerospace

FOCUSED="${FOCUSED_WORKSPACE:-$($AEROSPACE list-workspaces --focused 2>/dev/null)}"
[ -z "$FOCUSED" ] && exit 0

# One query for every window on every workspace ("3|Ghostty"), deduped by awk
# to one line per workspace/app pair — one icon per app, however many windows
# it has. Held in an array so the per-workspace scan below spawns nothing.
LINES=()
while IFS= read -r line; do
  LINES+=("$line")
done <<< "$($AEROSPACE list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null | awk '!seen[$0]++')"

args=()

for sid in $($AEROSPACE list-workspaces --all 2>/dev/null); do
  icons=""
  for line in "${LINES[@]}"; do
    [ "${line%%|*}" = "$sid" ] || continue
    __icon_map "${line#*|}"
    icons="$icons$icon_result"
  done

  if [ "$sid" = "$FOCUSED" ]; then
    args+=(--set "space.$sid" drawing=on background.drawing=on
           label.color=$BASE icon.color=$BASE)
  elif [ -n "$icons" ]; then
    args+=(--set "space.$sid" drawing=on background.drawing=off
           label.color=$BLUE icon.color=$SUBTEXT)
  else
    # empty and not focused — take it off the bar entirely
    args+=(--set "space.$sid" drawing=off)
    continue
  fi

  if [ -n "$icons" ]; then
    args+=(label="$icons" label.drawing=on)
  else
    args+=(label.drawing=off)
  fi
done

[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
