#!/bin/sh
# Join only reciprocal companions adjacent in the same session. Linked
# windows share options but may have different neighbors: keep their caps.
tmux list-windows -a -F '#{session_id}|#{window_id}|#{@claude_companion}|#{@claude_source}|#{window_linked}' |
  awk -F '|' '
    { session[NR]=$1; id[NR]=$2; peer[NR]=$3; source[NR]=$4; linked[NR]=$5 }
    END {
      for (i=1; i<=NR; i++) {
        side="-"
        if (!linked[i]) {
          if (i<NR && session[i]==session[i+1] && !linked[i+1] &&
              peer[i]==id[i+1] && source[i+1]==id[i]) side="right"
          if (i>1 && session[i]==session[i-1] && !linked[i-1] &&
              source[i]==id[i-1] && peer[i-1]==id[i]) side="left"
        }
        print id[i], side
      }
    }' |
  while read -r id side; do
    if [ "$side" = - ]; then
      tmux set-option -w -t "$id" -u @glue
    else
      tmux set-option -w -t "$id" @glue "$side"
    fi
  done
