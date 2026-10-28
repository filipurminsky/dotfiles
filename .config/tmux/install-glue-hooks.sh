#!/bin/sh
# Remove only our old append-based handlers, preserving unrelated hooks.
set -eu
for hook in after-new-window window-renamed window-unlinked window-linked after-select-window session-window-changed; do
  tmux show-hooks -g "$hook" | while read -r slot command; do
    case "$command" in
      *glue-sync.sh*)
        if [ "$slot" != "${hook}[42]" ]; then tmux set-hook -gu "$slot"; fi ;;
    esac
  done
  tmux set-hook -g "${hook}[42]" "run-shell -b '$HOME/.config/tmux/glue-sync.sh'"
done
