#!/bin/bash

# Toggle open/kill of "task manager"

if [ "$(pgrep -c top)" -gt 0 ]; then
  pkill top
else
  /usr/bin/alacritty --config-file ${HOME}/.dotfiles/.config/alacritty/grave.toml --class grave -e top
fi
