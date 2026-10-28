#!/usr/bin/env bash
# Single driver for every workspace item.
#
# Events refresh focus immediately; a slow poll catches background windows.
# Reconcile workspace items too, including auto-created display workspaces.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/icon_map.sh"
source "$CONFIG_DIR/plugins/workspace-item.sh"

AEROSPACE=${AEROSPACE:-/opt/homebrew/bin/aerospace}

FOCUSED="${FOCUSED_WORKSPACE:-$($AEROSPACE list-workspaces --focused 2>/dev/null)}"
[ -z "$FOCUSED" ] && exit 0

# One query for every window on every workspace ("3|Ghostty"), deduped by awk
# to one line per workspace/app pair — one icon per app, however many windows
# it has. Held in an array so the per-workspace scan below spawns nothing.
WINDOWS=$($AEROSPACE list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null) || exit 0
LINES=()
while IFS= read -r line; do
  LINES+=("$line")
done <<< "$(awk '!seen[$0]++' <<< "$WINDOWS")"

args=()
WORKSPACES=$($AEROSPACE list-workspaces --all 2>/dev/null) || exit 0
[ -n "$WORKSPACES" ] || exit 0
BAR_JSON=$(sketchybar --query bar) || exit 0
ITEMS=$(jq -er '.items | select(type == "array") | map(select(startswith("space."))) | join("\n")' <<< "$BAR_JSON") || exit 0
contains_line() { case $'\n'"$1"$'\n' in *$'\n'"$2"$'\n'*) return 0 ;; *) return 1 ;; esac; }
CHANGED=no
SPACE_ITEMS=()

while IFS= read -r sid; do
  [ -n "$sid" ] || continue
  SPACE_ITEMS+=("space.$sid")
  if ! contains_line "$ITEMS" "space.$sid"; then
    add_workspace "$sid"
    args+=(--move "space.$sid" before front_app)
    CHANGED=yes
  fi
  icons=""
  for line in "${LINES[@]}"; do
    [ "${line%%|*}" = "$sid" ] || continue
    __icon_map "${line#*|}"
    icons="$icons$icon_result"
  done

  if [ "$sid" = "$FOCUSED" ]; then
    args+=(--set "space.$sid" drawing=on background.drawing=on
           label.color="$BASE" icon.color="$BASE" background.color="$BLUE")
  elif [ -n "$icons" ]; then
    args+=(--set "space.$sid" drawing=on background.drawing=off
           label.color="$BLUE" icon.color="$BLUE")
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
done <<< "$WORKSPACES"

while IFS= read -r item; do
  [ -n "$item" ] || continue
  if ! contains_line "$WORKSPACES" "${item#space.}"; then
    args+=(--remove "$item")
    CHANGED=yes
  fi
done <<< "$ITEMS"

if [ "$CHANGED" = yes ]; then
  for item in "${SPACE_ITEMS[@]}"; do args+=(--move "$item" before front_app); done
  args+=(--remove spaces --add bracket spaces "${SPACE_ITEMS[@]}"
    --set spaces background.drawing=on background.color="$SURFACE0"
    background.corner_radius=5 background.height=22)
fi

[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
