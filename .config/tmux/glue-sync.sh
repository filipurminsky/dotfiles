#!/bin/sh
# Tag windows so the status bar can "glue" an nvim window to its Claude window
# (named "🤖 <nvim name>", spawned immediately to its right):
#   @glue=left  on the 🤖 window           -> square LEFT edge
#   @glue=right on the matching nvim window -> square RIGHT edge, no trailing gap
#   (unset)     everything else             -> normal rounded tab
# Re-derived from names on every hook, so it is self-cleaning. Current session
# only (no -a), so a 🤖 window in one session never glues an nvim in another.
prefix='🤖 '
tmux list-windows -F '#{window_id}|#{window_name}' | while IFS='|' read -r id name; do
  case "$name" in
    "$prefix"*)
      tmux set-option -w -t "$id" @glue left ;;
    *)
      if tmux list-windows -F '#{window_name}' | grep -qxF -- "$prefix$name"; then
        tmux set-option -w -t "$id" @glue right
      else
        tmux set-option -w -t "$id" -u @glue
      fi ;;
  esac
done
