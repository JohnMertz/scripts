#!/bin/bash

RUNNING=$(pgrep ncmpcpp)

if [ "$RUNNING" ]; then
  kill $RUNNING 2&>1 /dev/null
else
  echo "starting"
  alacritty -e /usr/bin/ncmpcpp
fi
