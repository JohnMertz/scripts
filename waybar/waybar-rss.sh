#!/usr/bin/env bash

if [[ "$1" == 'open' ]]; then
  alacritty -e newsboat
else
  newsboat -x reload
  COUNT=$(newsboat -x print-unread | cut -d ' ' -f 1)

  if [[ $COUNT =~ [0-9]+ ]]; then
    echo '{"text": "'$COUNT'", "tooltip": "'$COUNT' unread blogs", "class": "RSS"}'
  else
    echo '{none}'
  fi
fi

