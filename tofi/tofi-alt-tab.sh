#!/bin/bash
swaymsg -t get_tree |
  jq -r '.nodes[].nodes[] | if .nodes then [recurse(.nodes[])] else [] end + .floating_nodes | .[] | select(.nodes==[]) | if .app_id then ((.app_id | tostring) + " -- " + .name) else .name end' |
  grep -v __i3_scratch |
  sed -e 's/^.*\-\- \(.*\)$/\1/' |
  sed -e 's/^\(.*\) [—-] .*$/\1/' |
  sed -e 's/^\([0-9]*\)\t*\(.*\)/\2 \1/' |
  tofi --output $(swaymsg -t get_outputs | jq -r '.[] | select(.focused ).name') --config $HOME/.dotfiles/.config/tofi/sidebar.toml --prompt-text Window | {
  read -r
  #id=`echo $REPLY | rev | cut -d' ' -f1 | rev`
  id=$(echo $REPLY)
  swaymsg "[title='$id']" focus
}
echo $id $REPLY
