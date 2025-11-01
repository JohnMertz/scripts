#!/bin/bash

# Toggle open/kill of pavucontrol

RUNNING=$(pgrep pavucontrol)

if [ "$RUNNING" ]; then
  kill $RUNNING 2 /dev/null &>1
else
  /usr/bin/pavucontrol
fi
