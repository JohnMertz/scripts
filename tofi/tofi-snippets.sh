#!/usr/bin/env bash
# Paste snippet to mouse location, then restore clipboard

# Maintain list of snippets in private repository
cd ${HOME}/.private-scripts/snippets

HEIGHT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused).rect.height')
VERT=""
if [[ "$(swaymsg -t get_outputs | jq -r '.[] | select(.focused).model')" == "DASUNG" ]]; then
  VERT="-vertical"
  HEIGHT=1564
fi

# Back-up anything already in the clipboard
OLD="$(wl-paste -p)"

# Get input from Tofi
INPUT="$(find ./ -type f | sed -E 's/\.\///' | sort | tofi --output $(swaymsg -t get_outputs | jq -r '.[] | select(.focused ).name') --prompt-text 'Snippets: ' --height $HEIGHT --config ${HOME}/.dotfiles/.config/tofi/sidebar${VERT}.toml)"

# Ignore if returned file does not exist
if [ -e "$INPUT" ]; then

  # Copy file contents to clipboard and allow only one paste
  wl-copy -p "$(cat $INPUT)"

  # Paste at focus cursor
  YDOTOOL_SOCKET=/tmp/.ydotool_socket ydotool click 0xC2

  sleep 1
  # Restored backed-up clipboard
  echo "$OLD" | wl-copy -p

fi
