#!/bin/bash

# Create a reasonably well organized notification with disk usage stats

notify-send Disks \
  "$(lsblk -o NAME,SIZE,FSUSE%,MOUNTPOINT | grep -vP '^loop' |
    sed 's/MOUNTPOINT/MOUNT/' | sed -e 's/│ └─/+---/' |
    sed -e 's/  └─/+---/' | sed -e 's/├─/+-/' | sed -e 's/└─/+-/' |
    awk {'printf "%-20s %-7s %-    6s %-7s\n", substr($1, 1, 20), $2, $3, $4'})"
