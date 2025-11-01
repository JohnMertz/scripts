#!/bin/bash

# Toggle or set the visibility of Waybar

# The current state is tracked using file. If present, bar is thought to be hidden.
# Waybar doesn't provide a simple way of knowing the current state, so we might be out of sync.
STATE_FILE="${HOME}/.local/state/.waybar_hidden"

ARG=$1

# Toggle if no argument is given
[[ $ARG == "" ]] && ARG="toggle"

if [[ $ARG == "toggle" ]]; then
  # Remove state file if it exists
  if [[ -e "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
  # create it if it does not
  else
    touch "$STATE_FILE"
  fi

elif [[ $ARG == "hide" ]]; then
  # Create state file if it does not exist
  if [[ ! -e "$STATE_FILE" ]]; then
    touch "$STATE_FILE"
  # Otherwise the user might be confused. Exit with warning if we already think the bar is hiden
  else
    echo "I think it's already hidden. You can use the 'invert' option if this is reversed"
    exit
  fi

elif [[ $ARG == "show" ]]; then
  # Remove the state file if it exists
  if [[ -e "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
  # Otherwise the user might be confused. Exit with warning if we already think the bar is shown
  else
    echo "I think it's already shown. You can use the 'invert' option if this is reversed"
    exit
  fi

# If we are out of sync, 'invert' lets us toggle the bar without updating the state file
elif [[ $ARG != "invert" ]]; then
  echo "Invalid argument"
fi

# Actually toggle the bar(s)!
for i in $(pgrep waybar | cut -d " " -f 1); do
  kill -s SIGUSR1 $1
done
