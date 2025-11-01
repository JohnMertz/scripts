#!/bin/bash

# Wrapper for backlightctl to simplify interaction with waybar element

# Prevent duplicate processes from running into one another with a lockfile
LOCK=/tmp/brightness-lock
[ -e $LOCK ] && exit || touch $LOCK

# Provide fallback icon theme if ICON_THEME is not defined
[[ -z ICON_THEME ]] && ICON_THEME=Adwaita

# Use local user .icons directory if it exists, else use /usr/share/icons
[[ -d ${HOME}/.icons/$ICON_THEME ]] && ICON_DIR=${HOME}/.icons || ICON_DIR=/usr/share/icons

## Translate user-friendly CLI argument to brightnessctl option

# Default action is to just print the current percent brightness
if [ -z $1 ]; then
  ACTION="info"
# 'up' argument increments brightness
elif [ $1 == 'up' ]; then
  ACTION="set +1%"
# 'down' argument decrements brightness
elif [ $1 == 'down' ]; then
  ACTION="set 1%-"
else
  echo "Invalid argument $1"
fi

# Aquire a consistent notification ID so that we can update an existing notify-send notification
if [ -e /tmp/brightness-notification ]; then
  NOTIFY_ID=$(cat /tmp/brightness-notification)
  [ -z /tmp/brightness-notification ] && rm /tmp/brightness-notification
fi

# Get current brightness
BRIGHTNESS=$(brightnessctl info | grep Current | sed -r 's/.*\((1?[0-9]?[0-9])%\).*/\1/')

# If brightness is already at 1 and action is not to increment, just print
if [[ $ACTION != 'set +1%' ]] && [[ $BRIGHTNESS -eq 1 ]]; then
  ACTION="info"

# Otherwise get output after desired action
else
  BRIGHTNESS=$(brightnessctl $ACTION | grep Current | sed -r 's/.*\((1?[0-9]?[0-9])%\).*/\1/')
fi

# 5 levels of brightness icons exist. Pick the one best suited for current brightness
if [[ $BRIGHTNESS -le 20 ]]; then
  ICON='-low'
elif [[ $BRIGHTNESS -le 40 ]]; then
  ICON='-low'
elif [[ $BRIGHTNESS -le 60 ]]; then
  ICON='-medium'
elif [[ $BRIGHTNESS -le 80 ]]; then
  ICON='-high'
else
  ICON='-full'
fi

# If we already have a notification ID, re-use it
if [ -z $NOTIFY_ID ]; then
  NOTIFY_ID=$(notify-send -e --app-name=waybar-backlight --category=backlight --urgency=low --hint=int:value:$BRIGHTNESS --icon=${ICON_DIR}/${ICON_THEME}/48x48@2x/devices/notification-display-brightness${ICON}.svg -p -t 1000 Backlight ${BRIGHTNESS}%)
# Otherwise capture the newly generated ID
else
  NOTIFY_ID=$(notify-send -e --app-name=waybar-backlight --category=backlight --urgency=low --hint=int:value:$BRIGHTNESS --icon=${ICON_DIR}/${ICON_THEME}/48x48@2x/status/notification-display-brightness${ICON}.svg -p -t 1000 -r $NOTIFY_ID Backlight ${BRIGHTNESS}%)
fi

# Create/update ID file
echo $NOTIFY_ID >/tmp/brightness-notification

# Log current brightness (used by idle daemon)
echo $BRIGHTNESS >${HOME}/.local/state/last_brightness

# Clean up lockfile
rm $LOCK
