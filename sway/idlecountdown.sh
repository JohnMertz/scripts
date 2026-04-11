#!/bin/bash
ID_FILE=$HOME/.local/state/idle_countdown
ICON=$HOME/.icons/Gruvbox/48x48/apps/gnome-panel-clock.svg
CATEGORY=swayidle

if [ -e $ID_FILE ]; then
  NOTIFY_ID=$(cat $ID_FILE)
  if [ -z $NOTIFY_ID ]; then
    rm $ID_FILE
  else
    NOTIFY_ID=" -r $NOTIFY_ID"
  fi
fi

for i in `seq 0 30`; do
  NOTIFY_ID=$(notify-send -e --app-name=$CATEGORY --category=$CATEGORY --urgency=low --icon=$ICON -p${NOTIFY_ID} -t 2000 "Sleeping" "in $(expr 30 - $i)")
  echo $NOTIFY_ID > $ID_FILE
  NOTIFY_ID=" -r $NOTIFY_ID"
  echo $NOTIFY_ID for $i
  sleep 1
done
