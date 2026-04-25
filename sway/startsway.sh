#!/bin/bash
rm $HOME/.swaylog
echo sway > $HOME/.local/state/last_login_gui
export SSH_AUTH_SOCK=~/.ssh/ssh-agent.sock
export SWAYSOCK="$HOME/.local/state/sway-ipc.sock"
export QT_QPA_PLATFORM="wayland-egl;wayland;xcb"
export QT_QPA_PLATFORMTHEME=qt5ct 
export QML_IMPORT_PATH="/usr/lib/qt/qml"
export QT_PLUGIN_PATH="/usr/lib/qt/plugins"
export QML2_IMPORT_PATH="/usr/lib/qt/qml"
export SDL_VIDEODRIVER="wayland"
export MOZ_ENABLE_WAYLAND="1"
export MOZ_WEBRENDER="1"
export XDG_SESSION_TYPE="wayland"
export XDG_CURRENT_DESKTOP="sway"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_DIRS="$XDG_DATA_DIRS:${HOME}/.config/flatpak/exports/share"
export CHROME_EXECUTABLE="/usr/bin/chromium"
export FLATPAK_IDE_LOG_LEVEL="0"
export "$( gnome-keyring-daemon --start )"

#WLR_RENDERER=vulkan sway --debug 2>> $HOME/.swaylog >> $HOME/.swaylog
WLR_RENDERER=gles2 sway --debug 2>> $HOME/.swaylog >> $HOME/.swaylog
#WLR_RENDERER=vulkan sway --debug 2>> $HOME/.swaylog >> $HOME/.swaylog
#WLR_RENDERER=gles2 $HOME/build/sway/build/sway/sway --debug 2>> $HOME/.swaylog >> $HOME/.swaylog
export SWAYSOCK=`sway --get-socketpath`
systemctl --user stop wallpapers.service
