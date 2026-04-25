#!/bin/bash
# vim: set ts=2 sw=2 expandtab :

export SWAYSOCK=$(ls /run/user/1000/sway-ipc.1000.*.sock)
VEND_PROD=17ef:30af
LAPTOP=eDP-1
LGTV=$(swaymsg -t get_outputs | jq -r '.[] | select(.model=="LG TV SSCR2") | .name')
DASUNG=$(swaymsg -t get_outputs | jq -r '.[] | select(.model=="DASUNG") | .name')
CURRENT_WORKSPACE=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true) | .name')
STATE_FILE=${HOME}/.local/state/docked

if [[ "$1" == "connect" ]]; then
  [[ -e $STATE_FILE ]] && echo "Already connected" && exit
  swaymsg output $LGTV enable mode 3840x2160@60.000Hz scale 1 pos 0 0
  swaymsg output $DASUNG enable mode 3200x1800@40.064Hz scale 2 transform 90 pos 3840 0 allow_tearing yes
  swaymsg output $LAPTOP disable
  for i in 0 1 2 3 4 C1 C2 C3 C4; do
    if swaymsg -t get_workspaces | jq -e --arg i "$i" '.[] | select(.name==$i)' >/dev/null; then
      swaymsg workspace $i
      swaymsg move workspace to output $DASUNG
    fi
  done
  for i in 5 6 7 8 9 C5 C6 C7 C8 C9; do
    if swaymsg -t get_workspaces | jq -e --arg i "$i" '.[] | select(.name==$i)' >/dev/null; then
      swaymsg workspace $i
      swaymsg move workspace to output $LGTV
    fi
  done
  touch $STATE_FILE.nag
  if [[ -z $2 ]]; then
    swaynag -m "Dock connected and outputs automatically configured. Reverting in 10s..." -z "Keep" "rm $STATE_FILE.nag" -z "Revert" "${HOME}/scripts/sway/dock.sh disconnect" -o $LGTV &
    sleep 10
    if [ -e $STATE_FILE.nag ]; then
      pkill swaynag
      ${HOME}/scripts/sway/dock.sh disconnect
    fi
  fi
  touch $STATE_FILE
  logger "Lenovo Dock connected"
elif [[ "$1" == "disconnect" ]]; then
  [[ ! -e $STATE_FILE ]] && echo "Already disconnected" && exit
  swaymsg output $LAPTOP enable mode 2560x1600@60.001Hz scale 1.5 pos 0 0
  swaymsg output $LGTV disable
  swaymsg output $DASUNG disable 
  rm $STATE_FILE*
  logger "Lenovo Dock disconnected"
elif [[ "$1" == "startup" ]]; then
  [[ -e $STATE_FILE ]] && rm $STATE_FILE
  if [[ "$(lsusb | grep $VEND_PROD)" == "" ]]; then
    $0 disconnect
  else
    $0 connect force
  fi
else
  echo "Invalid command: $1"
fi

swaymsg workspace $CURRENT_WORKSPACE
