#!/bin/bash
swaymsg "[pid=$(echo $ALACRITTY_LOG | sed -E 's/\/tmp\/Alacritty-(.*)\.log/\1/')] urgent enable"
