#!/bin/bash

cd ${HOME}/scripts/tofi
if [ -z $1 ]; then
  echo -n "Argument required. Available arguments are:"
  for i in $(find -type d); do
    i=$(echo $i | sed -E 's/^\.\/?//')
    echo "  $i"
  done
  cd ${HOME}/.private-scripts/tofi
  $(find -type d)
  for i in $(find -type d); do
    i=$(echo $i | sed -E 's/^\.\/?//')
    echo "  $i"
  done
  exit
fi
if [ ! -e $1 ]; then
  cd ${HOME}/.private-scripts/tofi
  if [ ! -e $1 ]; then
    echo "$PWD/$1 is not a tofi directory"
    exit
  fi
fi
cd $1

HEIGHT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused).rect.height')
VERT=""
if [[ "$(swaymsg -t get_outputs | jq -r '.[] | select(.focused).model')" == "DASUNG" ]]; then
  VERT="-vertical"
  HEIGHT=1564
fi
ACTION=$(find ./ -executable -type f | sed -E 's/\.\///' | sort | tofi --output $(swaymsg -t get_outputs | jq -r '.[] | select(.focused ).name') --ascii-input true --prompt-text "${1^}: " --height $HEIGHT --config ${HOME}/.dotfiles/.config/tofi/sidebar${VERT}.toml --selection-background-padding='5,5,0,5')

[ "$ACTION" == '' ] && exit
./"$ACTION"
