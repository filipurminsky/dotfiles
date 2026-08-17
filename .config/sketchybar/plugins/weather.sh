#!/usr/bin/env bash
# Current condition + temperature from Open-Meteo (no API key needed).
# Use fixed coordinates rather than IP geolocation: a VPN can otherwise make
# the bar report weather from its tunnel's egress location.
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

LATITUDE="48.1486"    # Bratislava II
LONGITUDE="17.1077"

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

condition_from_wmo_code() {
  case "$1" in
    0) echo "Clear" ;;
    1|2|3) echo "Cloudy" ;;
    45|48) echo "Fog" ;;
    51|53|55|56|57) echo "Drizzle" ;;
    61|63|65|66|67|80|81|82) echo "Rain" ;;
    71|73|75|77|85|86) echo "Snow" ;;
    95|96|99) echo "Thunderstorm" ;;
    *) echo "Cloudy" ;;
  esac
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

# 2. Fetch fresh. The coordinates make the source independent of VPN routing.
# On failure, whatever step 1 painted stands.
JSON=$(curl -sf --max-time 5 "https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&current=temperature_2m,weather_code&timezone=Europe%2FBratislava" 2>/dev/null)
RAW=$(printf '%s' "$JSON" | jq -r '.current | "\(.weather_code)|\(.temperature_2m)"' 2>/dev/null)
case "$RAW" in
  *'|'*)
    CODE="${RAW%%|*}"
    TEMP="${RAW##*|}"
    RESP="$(condition_from_wmo_code "$CODE")|${TEMP}°C"
    ;;
  *) RESP="" ;;
esac
case "$RESP" in
  *'|'*)
    mkdir -p "${CACHE%/*}"
    printf '%s\n' "$RESP" > "$CACHE"
    render "$RESP"
    ;;
esac
