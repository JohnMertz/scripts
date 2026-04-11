#!/bin/bash

SUBSYSTEM='/sys/class/power_supply'
for i in $(ls $SUBSYSTEM); do
  if grep -Pq '^BAT' <<<$(echo $i); then
    if [[ $(cat $SUBSYSTEM/$i/status) == 'Discharging' ]]; then
      echo 'sleep' > /var/home/jpm/.local/state/idle_mode
      powerprofilesctl set power-saver
    fi
  elif [[ $i == 'AC' ]]; then
    continue
  else
    if [[ $(cat $SUBSYSTEM/$i/online) == '1' ]]; then
      echo 'none' > /var/home/jpm/.local/state/idle_mode
      powerprofilesctl set performance
      exit
    fi
  fi
done
