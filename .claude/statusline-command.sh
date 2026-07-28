#!/usr/bin/env bash
input=$(cat)

user=$(whoami)
host=$(hostname -s)
cwd=$(echo "$input" | jq -r '.cwd // empty')
[ -z "$cwd" ] && cwd=$(pwd)

# Shorten home directory to ~
home="$HOME"
cwd="${cwd/#$home/\~}"

# Git branch from workspace
branch=$(cd "${cwd/#\~/$HOME}" 2>/dev/null && git -c gc.auto=0 --no-optional-locks branch --show-current 2>/dev/null || true)

# Model display name
model=$(echo "$input" | jq -r '.model.display_name // empty')

# Context used percentage
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Build the status line with ANSI colors
# Agnoster-inspired: user@host | dir | git branch | model | context
printf "\033[1;32m%s@%s\033[0m" "$user" "$host"
printf " \033[1;34m%s\033[0m" "$cwd"

if [ -n "$branch" ]; then
  printf " \033[1;33m(%s)\033[0m" "$branch"
fi

if [ -n "$model" ]; then
  printf " \033[0;36m%s\033[0m" "$model"
fi

if [ -n "$used" ]; then
  printf " \033[0;35mctx:%s%%\033[0m" "$(printf '%.0f' "$used")"
fi
