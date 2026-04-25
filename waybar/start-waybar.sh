#!/bin/bash
# vim: set ts=2 sw=2 expandtab :

VERTICAL_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.model=="DASUNG") | .name')

cat ${HOME}/.config/waybar/config-vertical | sed "s/__OUTPUTS__/\"${VERTICAL_OUTPUT}\"/" > ${HOME}/.local/state/waybar-vertical
cat ${HOME}/.config/waybar/config | sed "s/__OUTPUTS__/\"!${VERTICAL_OUTPUT}\", \"\*\"/" > ${HOME}/.local/state/waybar

waybar -c ${HOME}/.local/state/waybar-vertical -s ${HOME}/.config/waybar/style-vertical.css &
waybar -c ${HOME}/.local/state/waybar -s ${HOME}/.config/waybar/style.css &

