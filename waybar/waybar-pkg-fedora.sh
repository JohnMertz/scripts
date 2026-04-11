#!/bin/bash

COUNTFILE=${HOME}/.local/state/$(hostname)-upgradeable
COUNT=0

function count() {
  RESULTS="`rpm-ostree upgrade --check 2> /dev/null | grep Diff: | sed 's/.*\([0-9][0-9]*\).*/\1/'`"
  COUNT=0
  for i in $RESULTS; do
    i=`echo $i | sed 's/;//'`
    let COUNT=$COUNT+$i
  done
}

if [ -e $COUNTFILE ] && [[ "$(date +%s) - $(stat -c %Y -- $COUNTFILE)" -gt 360 ]]; then
  echo $COUNTFILE is older than 1h. Forcing refresh.
  rm $COUNTFILE
fi

if [ "$1" == 'bar' ]; then
  if [ ! -e $COUNTFILE ]; then
    count
    echo $COUNT > $COUNTFILE
  else
    COUNT=`cat $COUNTFILE`
  fi
  if [ $COUNT -eq 0 ]; then
    echo '{"text": "🗹", "tooltip": "Up-to-date", "class": "up-to-date"}'
  else
    echo '{"text": "⭳'$COUNT'", "tooltip": "'$COUNT' updates available (click to download)", "class": "updateable"}'
  fi
elif [ "$SUDO_USER" != '' ]; then
  echo "Don't run with sudo. Run normally, but with a sudoer user"
elif [ $UID -eq 0 ]; then
  echo "Don't run as root. Run normally, but with a sudoer user"
elif [ "$1" == 'upgrade' ]; then
  /usr/bin/uxterm -e "rpm-ostree upgrade"
  count
  echo $COUNT > $COUNTFILE
elif [ "$1" == 'update' ]; then
  count
  echo $COUNT > $COUNTFILE
else
  echo "Missing argument: update, upgrade, bar"
fi
