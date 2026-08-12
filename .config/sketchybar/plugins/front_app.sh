#!/usr/bin/env bash
# $INFO carries the app name on front_app_switched. It's empty on a plain
# --update (startup), so ask AeroSpace which window has focus instead.

source "$CONFIG_DIR/plugins/hover.sh"
source "$CONFIG_DIR/plugins/icon_map.sh"

APP="$INFO"
if [ -z "$APP" ]; then
  APP=$(/opt/homebrew/bin/aerospace list-windows --focused --format '%{app-name}' 2>/dev/null | head -1)
fi
[ -z "$APP" ] && exit 0

__icon_map "$APP"

sketchybar --set "$NAME" icon="$icon_result" label="$APP"
