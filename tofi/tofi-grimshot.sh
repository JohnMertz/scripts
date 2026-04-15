#!/usr/bin/env bash
# vim: set ts=2 sw=2 expandtab :

SAVE="Save:"
[ -z $1 ] || [ "$1" == "copy" ] && SAVE="Copy:"

cd ${HOME}/scripts/tofi/grimshot

HEIGHT=$(swaymsg -t get_outputs | tr '\n' ' ' | sed -e 's/  */ /g' | sed -e 's/\(.*"focused": [a-z]*\),/\1\n/' | less | grep '"focused": true' | sed -e 's/.*"rect": {[^}]*"height": \([0-9]*\).*/\1/')
if [[ "$(swaymsg -t get_outputs | jq length)" == 1 ]]; then
  OPTIONS="$(find ./ -type f -exec basename {} \; | grep -v 'All Outputs' | sort)"
else
  OPTIONS="$(find ./ -type f -exec basename {} \; | sort)"
fi

INPUT=$(echo "$OPTIONS" | ${HOME}/.local/bin/tofi --output $(swaymsg -t get_outputs | jq -r '.[] | select(.focused ).name') --prompt-text $SAVE --height $HEIGHT --config ${HOME}/.dotfiles/.config/tofi/sidebar.toml)

[ "$INPUT" == '' ] && exit

[ "$SAVE" == 'Save:' ] && "./$INPUT" save || "./$INPUT" copy

