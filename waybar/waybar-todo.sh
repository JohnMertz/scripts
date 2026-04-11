#!/bin/bash

RUNNING=$(pgrep todotxt-machine)

if [ "$RUNNING" ]; then
  kill $RUNNING 2&>1 /dev/null
else
  /usr/bin/alacritty --title todotxt-machine -e ${HOME}/.pyenv/shims/todotxt-machine ${HOME}/export/todo.txt
fi
