#!/usr/bin/env bash
# active + wired + compressed, which is what Activity Monitor calls
# "Memory Used". vm_stat is instant, so this can poll cheaply.
# Note: memory_pressure reports something different (free/pressure, which
# counts inactive as available) and would read far lower.

source "$CONFIG_DIR/plugins/colors.sh"

read -r USED PCT <<< "$(vm_stat | awk -v total="$(sysctl -n hw.memsize)" '
  /page size of/           { ps = $8 }
  /Pages active/           { gsub(/\./, "", $3); act = $3 }
  /Pages wired down/       { gsub(/\./, "", $4); wir = $4 }
  /occupied by compressor/ { gsub(/\./, "", $5); comp = $5 }
  END {
    used = (act + wir + comp) * ps
    printf "%.1f %.0f", used / 1073741824, used / total * 100
  }')"

[ -z "$PCT" ] && exit 0

if   [ "$PCT" -ge 85 ]; then COLOR=$RED
elif [ "$PCT" -ge 65 ]; then COLOR=$YELLOW
else                         COLOR=$TEXT
fi

sketchybar --set "$NAME" icon="󰍛" icon.color="$COLOR" label="${PCT}%"
