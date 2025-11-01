#!/bin/bash

# Toggle open/kill of "task manager"

if [ "$(pgrep -c htop)" -gt 0 ]; then
  pkill htop
else
  /usr/bin/alacritty --config-file ${HOME}/.dotfiles/.config/alacritty/grave.toml --class Alacritty-grave -e htop
fi
