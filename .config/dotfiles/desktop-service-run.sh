#!/bin/sh
# Let launchd adopt the next incarnation of an already-running service.
# Waiting here avoids duplicate bars and an interruption during installation.
set -eu
binary=${1:?service executable required}
shift
name=${binary##*/}
while pgrep -x "$name" >/dev/null 2>&1; do
  sleep 5
done
exec "$binary" "$@"
