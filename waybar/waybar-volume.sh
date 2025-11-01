#!/bin/bash

# Wrapper for Pulseaudio for simpler use with Waybar

# Read it and weep...
function usage {
  cat <<EOF

$0 [up|down|set|mute-sink|mute-source] <value>

              Return current sink volume when no argument is provided
up <value>    Default 10 (percent)
down <value>  Default 10 (percent)
set <value>   Value is required (percent)
mute-sink     Default 'toggle'. Also supports 'yes', 'no'
mute-source   Default 'toggle'. Also supports 'yes', 'no'
EOF
  rm $LOCK
  exit
}

# Prevent multiple simultaneous actions with a lock file
LOCK=/tmp/volume-lock
[ -e $LOCK ] && echo "LOCKED" && exit || touch $LOCK

# Provide fallback icon theme if ICON_THEME is not defined
[[ -z ICON_THEME ]] && ICON_THEME=Adwaita

# Use local user .icons directory if it exists, else use /usr/share/icons
[[ -d ${HOME}/.icons/$ICON_THEME ]] && ICON_DIR=${HOME}/.icons || ICON_DIR=/usr/share/icons

CATEGORY="volume"
SINK='@DEFAULT_SINK@'
SOURCE='@DEFAULT_SOURCE@'

# Detect current volume
VOLUME=$(pactl get-sink-volume $SINK | head -n 1 | awk '{print $5}' | sed 's/%//')

# Detect current muted status of output
MUTE=$(pactl get-sink-mute $SINK | awk '{print $2}')

# Track notification ID so that we can update the same notification instead of making a new one
ID_FILE="/tmp/$CATEGORY-notification"
if [ -e $ID_FILE ]; then
  NOTIFY_ID=$(cat $ID_FILE)
  # Remove file if it does not contain a valid ID
  [ -z $NOTIFY_ID ] && rm $ID_FILE
fi

# If there is no ID yet, omit from notify-send command
[[ -z $NOTIFY_ID ]] && NOTIFY_ID="" || NOTIFY_ID=" -r $NOTIFY_ID"

## Prepare output text and action based on argument

# If no argument is given, just get current volume
if [ -z $1 ]; then
  ACTION="get-sink-volume $SINK"

# 'mute-sink' will mute output device
elif [[ "$1" == 'mute-sink' ]]; then
  ACTION="set-sink-mute $SINK"

# 'mute-source' will mute input device
elif [[ "$1" == 'mute-source' ]]; then
  CATEGORY="microphone"
  ACTION="set-source-mute $SOURCE"

# If already muted and action is not to unmute, exit early
elif [[ $MUTE == "yes" ]]; then
  NOTIFY_ID=$(notify-send -e --app-name=waybar-volume --category=$CATEGORY --urgency=low --icon=${HOME}/.icons/Gruvbox/48x48@2x/status/notification-audio-volume-off.svg -p${NOTIFY_ID} -t 1000 Muted "Ignoring change")
  sleep 1
  echo $NOTIFY_ID >$ID_FILE
  rm $LOCK
  exit

# 'up' increases volume of output
elif [[ "$1" == 'up' ]]; then
  ACTION="set-sink-volume $SINK"

# 'down' decreases volume of output
elif [[ "$1" == 'down' ]]; then
  ACTION="set-sink-volume $SINK"

# 'set' updates volume of output to precise value
elif [[ "$1" == 'set' ]]; then
  ACTION="set-sink-volume $SINK"

# all other arguments print 'usage' help menu
else
  usage
fi

## Handle default actions if no second argument is given
if [ -z $2 ]; then

  # exit with 'usage' help menu if 'set' provided without value
  [ "$1" == 'set' ] && usage

  # default to 'toggle' action if 'mute' provided without second argument
  if [ "$1" == 'mute-sink' ] || [ "$1" == 'mute-source' ]; then
    ACTION="${ACTION} toggle"

  # If first argument was 'up' treat as increment value
  elif [ "$1" == 'up' ]; then
    # Try to increment by 10%
    ((VOLUME += 10))
    # Clamp to 150% if this is exceeded
    [[ $VOLUME -gt 150 ]] && VOLUME=150
    ACTION="${ACTION} ${VOLUME}%"

  # If first argument was 'down' treat as decrement value
  elif [ "$1" == 'down' ]; then
    # Try to increment by 10%
    ((VOLUME -= 10))
    # Clamp to 0% if this is exceeded
    [[ $VOLUME -lt 0 ]] && VOLUME=0
    ACTION="${ACTION} ${VOLUME}%"

  fi

## Handle second arguments when provided
else

  if [ "$1" == 'mute-sink' ] || [ "$1" == 'mute-source' ]; then
    # 'mute' actions expect 'yes', 'no' or 'toggle'
    if [ "$2" == 'yes' ] || [ "$2" == 'no' ] || [ "$2" == 'toggle' ]; then
      ACTION="${ACTION} $2"
    # All other arguement fail with 'usage' help menu
    else
      usage
    fi

  elif [ "$1" == 'up' ]; then
    # 'up' expects a numeric second argument
    if [[ $2 =~ ^[0-9]+$ ]]; then
      # Attempt to increment by second argument
      ((VOLUME += $2))
      # Clamp to 150% if this is exceeded
      [[ $VOLUME -gt 150 ]] && VOLUME=150
      ACTION="${ACTION} ${VOLUME}%"
    # non-numerals fail with 'usage' help menu
    else
      usage
    fi

  elif [ "$1" == 'down' ]; then
    # 'down' expects a numeric second argument
    if [[ $2 =~ ^[0-9]+$ ]]; then
      # Attempt to increment by second argument
      ((VOLUME -= $2))
      # Clamp to 150% if this is exceeded
      [[ $VOLUME -lt 0 ]] && VOLUME=0
      ACTION="${ACTION} ${VOLUME}%"
    # non-numerals fail with 'usage' help menu
    else
      usage
    fi

  elif [ "$1" == 'set' ]; then
    # 'set' expects a numeric second argument
    if [[ "$2" =~ '^[0-9]+$' ]]; then
      # Attempt to volume to second argument
      VOLUME=$2
      # Clamp to 0% if below
      [[ $VOLUME -lt 0 ]] && VOLUME=0
      # Clamp to 150% if above
      [[ $VOLUME -gt 150 ]] && VOLUME=150
      ACTION="${ACTION} ${VOLUME}"
    # non-numerals fail with 'usage' help menu
    else
      usage
    fi

  fi
fi

# Apply action
pactl $ACTION >/dev/null

# Fetch new mute state
MUTE=$(pactl get-sink-mute $SINK | awk '{print $2}')

# Assign appropriate icon based on new volume value
if [[ $VOLUME -eq 0 ]] || [[ $MUTE == "yes" ]]; then
  ICON="off"
elif [[ $VOLUME -le 34 ]]; then
  ICON="low"
elif [[ $VOLUME -le 67 ]]; then
  ICON="medium"
else
  ICON="high"
fi
ICON=${ICON_DIR}/${ICON_THEME}/48x48@2x/status/notification-audio-volume-${ICON}.svg

# Unique notifications if the action was to toggle mute
if [ "$1" == 'mute-source' ] || [ "$MUTE" == "yes" ]; then
  NOTIFY_ID=$(notify-send -e --app-name=waybar-volume --category=$CATEGORY --urgency=low --icon=$ICON -p${NOTIFY_ID} -t 1000 Muted ${MUTE})

# Otherwise provide volume
else
  NOTIFY_ID=$(notify-send -e --app-name=waybar-volume --category=$CATEGORY --urgency=low --hint=int:value:$VOLUME --icon=$ICON -p${NOTIFY_ID} -t 1000 Volume ${VOLUME}%)
fi

# Update notification ID
echo $NOTIFY_ID >$ID_FILE

# Clean up lockfile
rm $LOCK
