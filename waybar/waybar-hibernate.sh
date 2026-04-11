#!/bin/bash

FILE="$HOME/.local/state/hibernate_inhibitor"
if [ -e $FILE ]; then
  INHIBITED=1
else
  INHIBITED=0
fi

if [ -z $1 ] || [[ "$1" == "bar" ]]; then
  if [[ $INHIBITED == 1 ]]; then
    echo '{"text":"☕","icon":"☕","tooltip":"Allow hibernation","class":"enabled"}'
  else
    echo '{"text":"💤","icon":"💤","tooltip":"Prevent hibernation","class":"disabled"}'
  fi
elif [[ "$1" == "toggle" ]]; then
  if [[ $INHIBITED == "1" ]]; then
    rm $FILE
  else
    touch $FILE
  fi
else
  echo "Invalid argumuent $1"
fi
