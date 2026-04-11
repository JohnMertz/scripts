#!/bin/bash

PROFILES=`gsettings get org.gnome.Terminal.ProfilesList list | sed -e 's/\[\(.*\)\]/\1/' |sed -e "s/[\',]//g"`
for i in $PROFILES; do
  CURRENT=`gsettings get org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${i}/ visible-name | sed -e "s/'\(.*\)'/\1/"`
  if [[ $1 == $CURRENT ]]; then
    for j in `gsettings list-keys org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${i}/`; do
      k=`gsettings get org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${i}/ $j`
      #echo $k
      echo gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/ $j \'$k\'
      gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/ $j "$k"
    done
    exit
  fi
done
