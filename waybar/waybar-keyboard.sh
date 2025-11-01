#!/bin/bash

# Rotate keyboard layouts or open OSK.
# This script expects Dvorak as the primary layout and will require modification for others.

# Expect input device name (from `swaymsg -t get_inputs`)
INPUTNAME="AT Translated Set 2 keyboard"

# Fetch the current layout
ACTIVELAYOUT=$(swaymsg -t get_inputs | jq -r ".[] | select(.name==\"$INPUTNAME\") | .xkb_active_layout_name")

# Map all available layouts to an array
mapfile -t AVAILABLELAYOUTS < <(swaymsg -t get_inputs | jq -r ".[] | select(.name==\"$INPUTNAME\") | .xkb_layout_names" | sed 's/[][,]//g' | sed 's/^ *//g' | grep -P '.')

# Get index of current layout within array (required for rotation)
ACTIVEINDEX=0
for i in "${AVAILABLELAYOUTS[@]}"; do
  if [[ "$i" == '"'$ACTIVELAYOUT'"' ]]; then
    break
  else
    ((ACTIVEINDEX += 1))
  fi
done

# 'bar' will be the action if none is specified
[[ -z $1 ]] && ACTION=bar || ACTION=$1

# 'osk' action will enable/disable the onscreen-keyboard
if [[ $ACTION == 'osk' ]]; then
  # Track current state in a file for easier toggling
  FILE=/home/jpm/.local/state/onscreen-keyboard
  # If file exists, it is already enabled. Remove file and disable it.
  if [ -f $FILE ]; then
    rm $FILE
    busctl call --user sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0 SetVisible b false
  # If file does not exists, it is not enabled. Create file and enable it.
  else
    touch $FILE
    busctl call --user sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0 SetVisible b true
  fi

# 'rotate' action cycles through available layouts and then prints the new layout details for waybar
elif [[ $ACTION == 'rotate' ]]; then
  # Simpler just to use 'next' to rotate input layouts
  swaymsg input type:keyboard xkb_switch_layout next
  $0 bar

# otherwise interpret all other arguments as 'bar'
else
  SHORT=$(echo $ACTIVELAYOUT | sed -r 's/.*\(([[:alpha:]]*)\).*/\1/')
  # Dvorak is my primary. It doesn't have a very short 'SHORT' name, but I know what it is.
  # This is a special case to manually shorten it to DV
  [[ "$SHORT" == "Dvorak" ]] && SHORT="DV"
  # Output JSON for Waybar
  if [[ $ACTIVEINDEX -ne 0 ]]; then
    echo '{"text": "⌨  '$SHORT'", "tooltip": "Rotate keyboard layout", "class": "alternate"}'
  else
    echo '{"text": "⌨  '$SHORT'", "tooltip": "Rotate keyboard layout", "class": "primary"}'
  fi
fi
