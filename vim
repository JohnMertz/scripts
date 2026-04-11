#!/bin/bash

FLATPAK=0
if [[ "$(which flatpak 2>/dev/null)" != "" ]]; then
  flatpak --user info io.neovim.nvim >/dev/null
  [[ "$?" == "0" ]] && FLATPAK=1
fi

if [[ "$FLATPAK" == "1" ]]; then
  flatpak --user run io.neovim.nvim $@
elif [[ "$(which nvim 2>/dev/null)" != "" ]]; then
  nvim $@
elif [[ "$(which vim 2>/dev/null)" != "" ]]; then
  vim $@
elif [[ "$(which vi 2>/dev/null)" != "" ]]; then
  vi $@
else
  echo "You don't have io.neovim.nvim (flatpak), nvim, vim, or vi"
fi
