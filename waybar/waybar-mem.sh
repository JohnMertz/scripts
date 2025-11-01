#!/bin/bash

# Create a reasonably well organized notification with memory usage stats

notify-send -t 0 'Memory Usage' "$(free -h |
  awk '{printf(\"%6s %6s %6s %6s\n\", $1, $2, $3, $4)}' |
  sed -r 's/(.*) shared$/       \1/')"
