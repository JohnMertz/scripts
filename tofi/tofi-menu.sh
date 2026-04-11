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

HEIGHT=$(swaymsg -t get_outputs | tr '\n' ' ' | sed -e 's/  */ /g' | sed -e 's/\(.*"focused": [a-z]*\),/\1\n/' | less | grep '"focused": true' | sed -e 's/.*"rect": {[^}]*"height": \([0-9]*\).*/\1/')

exec "./$(find ./ -executable -type f | sed -E 's/\.\///' | tofi --output $(swaymsg -t get_outputs | jq -r '.[] | select(.focused ).name') --prompt-text 'Power: ' --height $HEIGHT --config ${HOME}/.dotfiles/.config/tofi/sidebar.toml --selection-background-padding='5,5,0,5')" 2>/dev/null
