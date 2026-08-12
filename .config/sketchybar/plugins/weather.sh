#!/usr/bin/env bash
# Current condition + temperature from wttr.in (no API key needed).
# Location is IP-based when CITY is empty — note the corporate VPN can shift
# that to the tunnel's egress city, so pin CITY if readings look foreign.
#
# Order matters here: the last good reading is painted from cache *before*
# the network fetch, so a bar reload shows weather instantly instead of a
# blank item for the length of a curl timeout. wttr.in throttles bursts of
# requests (every reload fetches), so the cache also covers failed fetches.
#
# This file must stay executable — sketchybar execs plugins directly and a
# 644 script fails silently: no timer ticks, no events, nothing.

source "$CONFIG_DIR/plugins/colors.sh"
source "$CONFIG_DIR/plugins/hover.sh"

CITY=""   # e.g. "Bratislava" — URL-encode spaces as +

CACHE="$HOME/.cache/sketchybar/weather"
MAX_AGE_MIN=180   # stale cache beyond this is worse than no item

render() {  # $1 = "Condition|+21°C"
  local cond temp icon
  cond=$(printf '%s' "${1%%|*}" | tr '[:upper:]' '[:lower:]')
  temp="${1##*|}"
  temp="${temp#+}"
  case "$cond" in
    *thunder*)                        icon="󰖓" ;;
    *snow*|*sleet*|*blizzard*|*ice*)  icon="󰖘" ;;
    *rain*|*drizzle*|*shower*)        icon="󰖗" ;;
    *fog*|*mist*|*haze*)              icon="󰖑" ;;
    *overcast*)                       icon="󰖐" ;;
    *cloud*)                          icon="󰖕" ;;
    *clear*|*sunny*)                  icon="󰖙" ;;
    *)                                icon="󰖕" ;;
  esac
  sketchybar --set "$NAME" drawing=on icon="$icon" icon.color=$YELLOW label="$temp"
}

# 1. Paint the cached reading immediately, if it's fresh enough.
PAINTED=no
if [ -f "$CACHE" ]; then
  AGE_MIN=$(( ($(date +%s) - $(stat -f %m "$CACHE")) / 60 ))
  if [ "$AGE_MIN" -le "$MAX_AGE_MIN" ]; then
    IFS= read -r CACHED < "$CACHE"
    case "$CACHED" in *'|'*) render "$CACHED"; PAINTED=yes ;; esac
  fi
fi
# Nothing to paint yet — hide rather than show an empty pill.
[ "$PAINTED" = yes ] || sketchybar --set "$NAME" drawing=off

# 2. Fetch fresh. ?m forces metric regardless of what the IP looks like.
# wttr.in serves some failures as HTTP 200 with an HTML body, so also
# require the | separator. On failure, whatever step 1 painted stands.
RESP=$(curl -sf --max-time 5 "https://wttr.in/${CITY}?m&format=%C|%t" 2>/dev/null)
case "$RESP" in
  *'|'*)
    mkdir -p "${CACHE%/*}"
    printf '%s\n' "$RESP" > "$CACHE"
    render "$RESP"
    ;;
esac
