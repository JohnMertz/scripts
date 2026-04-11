#!/bin/bash

function usage {
  echo "Usage: $0 [up|down|set|fade] <value>"
  echo "              Return current brightness volume when no argument is provided"
  echo "up <value>    Default 10 (percent)"
  echo "down <value>  Default 10 (percent)"
  echo "set <value>   Value is required (percent)"
  rm $LOCK
  exit
}

LOCK=/tmp/brightness-lock
CATEGORY="brightness"
ID_FILE="/tmp/$CATEGORY-notification"
DEVICE="intel_backlight"
ICON="${HOME}/.icons/Gruvbox/48x48@2x/status/notification-display-brightness.svg"

if [ -e $LOCK ]; then
  echo "LOCKED"
fi
touch $LOCK

if [ -e $ID_FILE ]; then
  NOTIFY_ID=$(cat $ID_FILE)
  if [ -z $NOTIFY_ID ]; then
    rm $ID_FILE
  else
    NOTIFY_ID=" -r $NOTIFY_ID"
  fi
fi

CURRENT=$(brightnessctl -P -d $DEVICE get)
if [ -z $1 ]; then
  NOTIFY_ID=$(notify-send -e --app-name=waybar-brightness --category=$CATEGORY --urgency=low --hint=int:value:$CURRENT --icon=$ICON -p${NOTIFY_ID} -t 1000 Brightness ${CURRENT}%)
  echo $NOTIFY_ID > $ID_FILE
  rm $LOCK
  exit
elif [[ "$1" == 'up' ]]; then
  ACTION="brightnessctl -P -d $DEVICE set"
elif [[ "$1" == 'down' ]]; then
  ACTION="brightnessctl -P -d $DEVICE set"
elif [[ "$1" == 'set' ]]; then
  ACTION="brightnessctl -P -d $DEVICE set"
else
  usage
fi

if [ -z $2 ]; then
  if [ "$1" == 'set' ]; then
    usage
  fi
  if [ "$1" == 'up' ]; then
    ((CURRENT+=10))
    if [[ $CURRENT -gt 100 ]]; then
      CURRENT=100
    fi
    ACTION="${ACTION} ${CURRENT}%"
  elif [ "$1" == 'down' ]; then
    ((CURRENT-=10))
    if [[ $CURRENT -lt 0 ]]; then
      CURRENT=0
    fi
    ACTION="${ACTION} ${CURRENT}%"
  fi
else
  if [ "$1" == 'up' ]; then
    if [[ $2 =~ ^[0-9]+$ ]]; then
      ((CURRENT+=$2))
      if [[ $CURRENT -gt 100 ]]; then
        CURRENT=100
      fi
      ACTION="${ACTION} ${CURRENT}%"
    else
      usage
    fi
  elif [ "$1" == 'down' ]; then
    if [[ $2 =~ ^[0-9]+$ ]]; then
      ((CURRENT-=$2))
      if [[ $CURRENT -lt 0 ]]; then
        CURRENT=0
      fi
      ACTION="${ACTION} ${CURRENT}%"
    else
      usage
    fi
  elif [ "$1" == 'set' ]; then
    if [[ "$2" =~ '^[0-9]+$' ]]; then
      CURRENT=$2
      if [[ $CURRENT -lt 0 ]]; then
        CURRENT=0
      elif [[ $CURRENT -gt 100 ]]; then
        CURRENT=100
      fi
      ACTION="${ACTION} ${CURRENT}"
    else
      usage
    fi
  fi
fi

$ACTION >/dev/null

NOTIFY_ID=$(notify-send -e --app-name=waybar-brightness --category=$CATEGORY --urgency=low --hint=int:value:$CURRENT --icon=$ICON -p${NOTIFY_ID} -t 1000 Brightness ${CURRENT}%)

echo $NOTIFY_ID > $ID_FILE
rm $LOCK
