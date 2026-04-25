#!/bin/bash

HEIGHT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused).rect.height')
VERT=""
if [[ "$(swaymsg -t get_outputs | jq -r '.[] | select(.focused).model')" == "DASUNG" ]]; then
  VERT="-vertical"
  HEIGHT=1564
fi
tofi-drun --output $(swaymsg -t get_outputs | jq -r '.[] | select(.focused ).name') --prompt-text "Run: " --height $HEIGHT --config ${HOME}/.dotfiles/.config/tofi/sidebar${VERT}.toml
