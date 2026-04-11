#!/bin/bash

PID=$(pgrep gammastep)
RUNNING=0
if [ -e $HOME/.local/state/gammastep.status ]; then
  RUNNING=`cat $HOME/.local/state/gammastep.status`
fi

ACTION=$1
if [[ "$1" == '' ]]; then
  ACTION='bar'
fi

if [[ $ACTION == 'bar' ]]; then
  :
elif [[ $ACTION == 'toggle' ]]; then
  if [ ! -z $PID ]; then
    kill -SIGUSR1 $PID
    if [[ $RUNNING == 0 ]]; then
      echo 1 > $HOME/.local/state/gammastep.status
    else
      echo 0 > $HOME/.local/state/gammastep.status
    fi
  else
    echo 'Gammastep is not running'
  fi
elif [[ $ACTION == 'start' ]]; then
  if [ ! -z $PID ]; then
    echo 'Gammastep is already running'
  else
    $HOME/scripts/distrobox/toolbox/gammastep.pl
  fi
elif [[ $ACTION == 'stop' ]]; then
  if [ ! -z $PID ]; then
    kill $PID
  else
    echo 'Gammastep is not running'
  fi
elif [[ $ACTION == 'enable' ]]; then
  if [ ! -z $PID ]; then
    if [[ $RUNNING != 0 ]]; then
      echo 'Already enabled'
    else
      kill -SIGUSR1 $PID
      echo 1 > $HOME/.local/state/gammastep.status
    fi
  else
    echo 'Gammastep is not running'
  fi
elif [[ $ACTION == 'disable' ]]; then
  if [ ! -z $PID ]; then
    if [ $RUNNING ]; then
      kill -SIGUSR1 $PID
      echo 0 > $HOME/.local/state/gammastep.status
    else
      echo 'Already disabled'
    fi
  else
    echo 'Gammastep in not running'
  fi
else
  echo "Invalid argument '$ACTION'. Use 'bar', 'toggle', 'start', 'stop', 'enable', 'disable'."
fi

RUNNING=0
if [ -e $HOME/.local/state/gammastep.status ]; then
  RUNNING=`cat $HOME/.local/state/gammastep.status`
fi
if [[ $RUNNING == 0 ]]; then
  echo '{"text":"ɣ","icon":"ɣ","tooltip":"Enable Gammastep","class":"disabled"}'
else
  echo '{"text":"ɣ","icon":"ɣ","tooltip":"Disable Gammastep","class":"enabled"}'
fi
