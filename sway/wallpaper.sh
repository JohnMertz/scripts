#!/bin/bash

EXISTING=$(pgrep swaybg)

# Get the number of wallpapers available
COUNT=$(find ${HOME}/wallpapers/ -type f | wc -l)

# Take first 10 characters from /dev/random, convert to decimal, then add them all together
RANDOM=$(echo "1$(head -n 1 /dev/random | cut -b 1-10 | od -A n -t d1 | sed -r 's/ *[\-]?([0-9]+)/+\1/g')%24" | bc)

# Get the modulus of RANDOM % COUNT to select a random wallpaper index
REMAINDER=$(echo "$RANDOM%$COUNT" | bc)

# Loop through available wallpapers until REMAINDER index is reached
INDEX=0
for i in $(find ${HOME}/wallpapers/ -type f); do
  if [[ $INDEX == $REMAINDER ]]; then
    # Apply new background ('fill' mode)
    swaybg -i $i -m fill &
    break
  fi
  let INDEX++
done

if [[ "$EXISTING" != "" ]]; then
  sleep 2
  kill $EXISTING
fi
