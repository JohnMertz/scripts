#!/bin/bash

ON=0
if [ -z $1 ]; then
  #echo "Argument not provided. Detecting current orientation"
  IN=''
  for i in `swaymsg -pt get_outputs`; do
    #echo $i
    if [[ $i == 'Output' ]]; then
      IN='OUTPUT'
      #echo "Found Output key: $i"
    elif [[ $IN == 'OUTPUT' ]]; then
      #echo "Found Output: $i"
      if [[ $i == 'eDP-1' ]]; then
        IN='EDP1'
      else
        IN=''
      fi
    elif [[ $IN == 'EDP1' ]]; then
      if [[ $i == 'Transform:' ]]; then
        #echo "Found transform key: $i"
        IN='TRANSFORM'
      fi
    elif [[ $IN == 'TRANSFORM' ]]; then
      #echo "Found transform value: $i"
      if [[ $i != 'normal' ]]; then
        ON=1
        #echo "Found non-default transform $i"
      fi
      break
    fi
  done
elif [[ $1 == 'on' ]]; then
  ON=0
elif [[ $1 == 'off' ]]; then
  ON=1
else
  echo "Invalid argument '$1'. Either 'on', 'off' or no argument to toggle"
  exit
fi

if [[ $ON == 0 ]]; then
  #echo "Tablet mode is off, enabling..."
  swaymsg output eDP-1 transform 270
else
  #echo "Tablet mode is on, disabing..."
  swaymsg output eDP-1 transform 0
fi
