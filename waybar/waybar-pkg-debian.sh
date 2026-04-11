#!/bin/bash

if [ "$1" == 'bar' ]; then
  if [ ! -e ${HOME}/.local/state/apt-upgradeable ]; then
    sudo apt update >/dev/null 2>/dev/null
    COUNT=`apt list --upgradable 2> /dev/null | wc -l`
    let COUNT--
    echo $COUNT > /home/jpm/.local/state/apt-upgradeable
  else
    COUNT=`cat ${HOME}/.local/state/apt-upgradeable`
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
  /usr/bin/uxterm -e "sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y && sudo apt-get clean -y && exit"
  COUNT=`apt list --upgradable 2> /dev/null | wc -l`
  let COUNT--
  echo $COUNT > /home/jpm/.local/state/apt-upgradeable
  if [ -e /var/run/reboot-required ]; then
    grep -B1 -A4 upgrade /var/log/apt/history.log | tail -n 6 | swaynag --config=${HOME}/.dotfiles/.config/sway/swaynag --edge=bottom --message="New packages require restart" --button="Restart Now" "sudo systemctl reboot" --dismiss-button="Later" --detailed-message --detailed-button "Show/Hide Upgrade Details"
  fi
elif [ "$1" == 'update' ]; then
  sudo apt update >/dev/null 2>/dev/null
  COUNT=`apt list --upgradable 2> /dev/null | wc -l`
  let COUNT--
  echo $COUNT > /home/jpm/.local/state/apt-upgradeable
else
  echo "Missing argument: update, upgrade, bar"
fi
