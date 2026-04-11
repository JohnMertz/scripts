#!/usr/bin/env bash

# Modified from: https://github.com/fourstepper/wofi-wifi-menu

# Starts a scan of available broadcasting SSIDs
# nmcli dev wifi rescan

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FIELDS=SECURITY,SSID

# Gives a list of known connections so we can parse it later
KNOWNCON=$(nmcli connection show)
# Really janky way of telling if there is currently a connection
CONSTATE=$(nmcli -fields WIFI g)

CURRSSID=$(LANGUAGE=C nmcli -t -f active,ssid dev wifi | awk -F: '$1 ~ /^yes/ {print $2}')

LIST=$(nmcli --fields "$FIELDS" device wifi list | sort | uniq | sed -r '/^SECURITY *SSID/d' | sed '/ --/d' | sed "/$CURRSSID/d" | sed -r 's/((WPA[123]|WEP) )+ */  /g')

if [[ "$CONSTATE" =~ "enabled" ]]; then
  TOGGLE="toggle off"
elif [[ "$CONSTATE" =~ "disabled" ]]; then
  TOGGLE="toggle on"
fi

HEIGHT=$(swaymsg -t get_outputs | tr '\n' ' ' | sed -e 's/  */ /g' | sed -e 's/\(.*"focused": [a-z]*\),/\1\n/' | less | grep '"focused": true' | sed -e 's/.*"rect": {[^}]*"height": \([0-9]*\).*/\1/')

CURR=''
if [ ! -z "$CURRSSID" ]; then
  CURR="  $CURRSSID\n"
fi

CHENTRY=$(echo -e "${TOGGLE}\nmanual\n${CURR}${LIST}" | uniq -u | ${HOME}/.local/bin/tofi --output $(swaymsg -t get_outputs | jq -r '.[] | select(.focused ).name') --prompt-text "Wi-Fi: " --height $HEIGHT --width 340 -c $HOME/.dotfiles/.config/tofi/sidebar.toml)
if [[ $CHENTRY == "" ]]; then
  exit
fi

CHSSID=$(echo "$CHENTRY" | sed -e 's/\([]\)  //g' | sed -e 's/ *$//g')

# If the user inputs "manual" as their SSID in the start window, it will bring them to this screen
if [ "$CHENTRY" = "manual" ]; then
  # Manual entry of the SSID and password (if appplicable)
  MSSID=$(echo "enter the SSID of the network (SSID,password)" | ${HOME}/.local/bin/tofi --output $(swaymsg -t get_outputs | jq -r '.[] | select(.focused ).name') --prompt-text "Password" --height $HEIGHT --width 340 -c $HOME/.dotfiles/.config/tofi/sidebar.toml)
  # Separating the password from the entered string
  MPASS=$(echo "$MSSID" | awk -F "," '{print $2}')

  # If the user entered a manual password, then use the password nmcli command
  if [ "$MPASS" = "" ]; then
    nmcli dev wifi con "$MSSID"
  else
    nmcli dev wifi con "$MSSID" password "$MPASS"
  fi

elif [ "$CHENTRY" = "toggle on" ]; then
  nmcli radio wifi on

elif [ "$CHENTRY" = "toggle off" ]; then
  nmcli radio wifi off

else
  if grep -q "$CHSSID" <<<$(echo $KNOWNCON); then
    nmcli con up "$CHSSID"
  else
    if [[ "$CHENTRY" =~ "" ]]; then
      WIFIPASS=$(echo "" | ${HOME}/.local/bin/tofi --output $(swaymsg -t get_outputs | jq -r '.[] | select(.focused ).name') --prompt-text "Password" --height $HEIGHT --width 340 -c $HOME/.dotfiles/.config/tofi/sidebar.toml)
      if [[ $WIFIPASS == "if connection is stored, hit enter" ]]; then
        unset WIFIPASS
      fi
    fi
    nmcli dev wifi con "$CHSSID" password "$WIFIPASS"
  fi
fi
