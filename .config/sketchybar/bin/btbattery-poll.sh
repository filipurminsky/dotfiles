#!/bin/sh
# Runs btbattery and caches the result for the sketchybar plugin to read.
#
# This exists because of TCC. CoreBluetooth aborts a process whose *responsible
# process* has no Bluetooth grant, and a plugin spawned by sketchybar inherits
# sketchybar as its responsible process — btbattery dies with SIGABRT, silently,
# no stderr and no crash report. A binary started by launchd is its own
# responsible process, so TCC judges btbattery on its own embedded
# Info.plist (NSBluetoothAlwaysUsageDescription) and lets it through.
#
# Hence: launchd runs this on a timer, the plugin only reads the cache file.
# Scheduled by ~/Library/LaunchAgents/local.sketchybar.btbattery.plist.

CACHE="$HOME/.cache/sketchybar"
mkdir -p "$CACHE"

OUT=$("$HOME/.config/sketchybar/bin/btbattery" Keychron 2>/dev/null)
CODE=$?

# "<exit-code> <percent>" — the code lets the plugin tell "keyboard is off"
# from "the read glitched", which look different in the bar.
printf '%s %s\n' "$CODE" "$OUT" > "$CACHE/keyboard-battery.tmp"
mv "$CACHE/keyboard-battery.tmp" "$CACHE/keyboard-battery"

/opt/homebrew/bin/sketchybar --trigger keyboard_battery 2>/dev/null
