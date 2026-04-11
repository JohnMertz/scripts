#!/usr/bin/env bash

FILE="${HOME}/.local/state/pomodoro"
LOG="${HOME}/.local/state/pomodoro.log"
CHIME="/usr/share/sounds/speech-dispatcher/electric-piano-3.wav"
NOW=$(date "+%s")

# Get the remaining text (eg. 29:59) from $NOW and $STARTED
function remainder_text {
  ELAPSED=$((NOW-STARTED))
  ELAPSED=$((ELAPSED-1))
  # If more than 30 minutes have elapsed, just return "00:00"
  if [[ $ELAPSED -eq 1800 ]]; then
    aplay $CHIME 2>/dev/null >/dev/null &
    # Get compeletion time now, since it will be logged in 10 seconds 
    TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo '{"text": "00:00", "tooltip": "Left-click to start new, right-click to reset", "class": "pomodoro-done"}'
    # Fork a notification to wait for confirmation
    RESULT=$(
      notify-send -e --app-name=waybar-pomodoro --category=pomodoro-timer --icon=${HOME}/.icons/Gruvbox/48x48@2x/categories/tomato.svg --action=Confirm=Confirm --action=Failed=Failed -t 10000 Pomodoro Complete & WAITPID=$!
      # If not confirmed in 10 seconds, I must not actually be attentively working, so bail out
      sleep 10 &
      wait -n $WAITPID $!
      kill $WAITPID
    )
    # Only if confirmed, log the pomodoro
    if [[ $RESULT == 'Confirm' ]]; then
      echo $TIME >> $LOG
      rm $FILE
    fi
    exit
  elif [[ $ELAPSED -gt 1800 ]]; then
    echo "00:00"
  else
    MINUTES=$((29-ELAPSED/60))
    SECONDS=$((59-ELAPSED%60))
    printf "%02d:%02d" $MINUTES $SECONDS
  fi
}

# Get a new STARTED time on resume by back-dating from NOW
function resume_seconds {
  MINUTES=$(echo -n $STARTED | sed 's/:.*//')
  SECONDS=$(echo -n $STARTED | sed 's/.*://')
  RESUME=$NOW
  RESUME=$((RESUME-1800+((MINUTES*60))+SECONDS))
  echo $RESUME
}

## Actions

if [[ "$1" == 'left' ]]; then
  # PAUSE/RESUME: If file exists, then we need to pause/resume
  if [[ -e $FILE ]]; then
    STARTED=$(cat $FILE)
    # RESUME: If STARTED is remaining text, resume by getting new STARTED epoch
    if [[ $STARTED =~ : ]]; then
      echo -n $(resume_seconds) > $FILE
      notify-send -e --app-name=waybar-pomodoro --category=pomodoro-timer --icon=${HOME}/.icons/Gruvbox/48x48@2x/categories/tomato.svg -t 1000 Pomodoro Resuming &
      unset STARTED
    # PAUSE: Otherwise, pause by writing current remaining text
    else
      TEXT=$(remainder_text)
      if [[ $TEXT == '00:00' ]]; then
        notify-send -e --app-name=waybar-pomodoro --category=pomodoro-timer --icon=${HOME}/.icons/Gruvbox/48x48@2x/categories/tomato.svg -t 1000 Pomodoro Started &
        echo -n $NOW > $FILE
        STARTED=$NOW
      else
        notify-send -e --app-name=waybar-pomodoro --category=pomodoro-timer --icon=${HOME}/.icons/Gruvbox/48x48@2x/categories/tomato.svg -t 1000 Pomodoro Paused &
        echo -n $TEXT > $FILE
        unset STARTED
      fi
    fi
  # START: Otherwise we need to start a new timer
  else
    notify-send -e --app-name=waybar-pomodoro --category=pomodoro-timer --icon=${HOME}/.icons/Gruvbox/48x48@2x/categories/tomato.svg -t 1000 Pomodoro Started &
    echo -n $NOW > $FILE
    STARTED=$NOW
  fi
# Remove any existing timer
elif [[ "$1" == 'right' ]]; then
  notify-send -e --app-name=waybar-pomodoro --category=pomodoro-timer --icon=${HOME}/.icons/Gruvbox/48x48@2x/categories/tomato.svg -t 1000 Pomodoro Reset &
  rm $FILE
fi

## Output

TOOLTIP="Left-click to pause, right-click to reset"
CLASS="pomodoro-running"

# If left-click action was to START a new timer, then we can just take a shortcut
if [[ -n $STARTED ]]; then
  TEXT="30:00"
# If the file exists, we need to interpret it's contents
elif [[ -e $FILE ]]; then
  STARTED=$(cat $FILE)
  # When paused, the content of the file is the remaining time text
  if [[ $STARTED =~ : ]]; then
    TOOLTIP="Left-click to resume, right-click to reset"
    TEXT=$STARTED
    CLASS="pomodoro-paused"
  # Otherwise it is the start time as an epoch number
  else
    # Avoid re-calculating on PAUSE
    if [[ -z $TEXT ]]; then
      TEXT=$(remainder_text)
    fi
    # Special case when no time is remaining
    if [[ $TEXT == '00:00' ]]; then
      TOOLTIP="Left-click to start new, right-click to reset"
      CLASS="pomodoro-done"
    fi
  fi
else
  TOOLTIP="Left-click to start a 30 minute timer"
  TEXT="🍅"
  CLASS="pomodoro"
fi

echo '{"text": "'$TEXT'", "tooltip": "'$TOOLTIP'", "class": "'$CLASS'"}'
