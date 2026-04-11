#!/bin/bash

HEIGHT=$(swaymsg -t get_outputs | tr '\n' ' ' | sed -e 's/  */ /g' | sed -e 's/\(.*"focused": [a-z]*\),/\1\n/' | less | grep '"focused": true' | sed -e 's/.*"rect": {[^}]*"height": \([0-9]*\).*/\1/')
${HOME}/.local/bin/tofi-drun --output $(swaymsg -t get_outputs | jq -r '.[] | select(.focused ).name') --prompt-text "Run: " --height $HEIGHT --config ${HOME}/.dotfiles/.config/tofi/sidebar.toml
