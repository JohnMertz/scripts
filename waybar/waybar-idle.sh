#!/bin/bash

# Wrapper for my custom idle to display current status in Waybar
# See ../sway/idle.sh

# File where desired idle behaviour is tracked
FILE="$HOME/.local/state/idle_mode"

# If file exists, get current state, otherwise default to 'fade'
[[ -e $FILE ]] && MODE=$(cat $FILE) || MODE="fade"

# Tooltip message
MSG="Change sleep mode ($MODE)"

# Prepare a pretty status icon based on the current mode
if [[ $MODE == "none" ]]; then
  ICON=""
elif [[ $MODE == "fade" ]]; then
  ICON=""
elif [[ $MODE == "dim" ]]; then
  ICON=""
elif [[ $MODE == "lock" ]]; then
  ICON=""
elif [[ $MODE == "sleep" ]]; then
  ICON=""
elif [[ $MODE == "hibernate" ]]; then
  ICON=""
fi

# Fallback if mode is unexpected
if [[ -z $ICON ]]; then
  ICON="🯄 "
  MSG="Error: Invalid mode ($MODE)"
fi

# Print Waybar-friendly JSON
echo '{"text":"'$ICON'","icon":"'$ICON'","tooltip":"'$MSG'","class":"'$MODE'"}'
