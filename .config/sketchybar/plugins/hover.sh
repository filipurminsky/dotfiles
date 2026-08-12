#!/usr/bin/env bash
# Hover highlight, sourced at the top of any plugin whose item subscribes to
# mouse.entered/mouse.exited. On those events it repaints the pill and exits
# the *caller* (this file is sourced, so exit propagates) — hover must never
# fall through to the plugin's real work (e.g. weather's network fetch).
#
# wifi and vpn draw no pill of their own; theirs is the shared "network"
# bracket, so hover repaints that instead.

source "$CONFIG_DIR/plugins/colors.sh"

_hover_target="$NAME"
case "$NAME" in
  wifi|vpn) _hover_target="network" ;;
esac

case "$SENDER" in
  mouse.entered) sketchybar --set "$_hover_target" background.color=$LINE;     exit 0 ;;
  mouse.exited)  sketchybar --set "$_hover_target" background.color=$SURFACE0; exit 0 ;;
esac
