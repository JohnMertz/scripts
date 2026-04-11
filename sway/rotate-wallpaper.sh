#!/bin/bash

PID=`cat /tmp/$USER-wallpaper.pid`

if [ $PID ]; then
  kill -SIGUSR1 $PID
else
  systemctl --user restart wallpapers.service
fi
