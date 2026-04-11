#!/bin/bash

# Required settings
host=192.168.0.24
port=8080

# Optional login for Kodi
user=kodi
pass=kodi

# Settings for netcat (local file)
local_hostname=$(hostname)
local_port=12345

show_help()
{
  cat<<EOF
Sends a video URL to Kodi
Usage: send-to-kodi.sh [URL]

If no URL is given, a dialog window is shown (requires zenity).

Supports:
Common file formats (mp4,flv,mp3,jpg and more)
Youtube (requires the Youtube plugin in Kodi)
Local media streaming (via netcat)
Manny more sites (requires youtube-dl)

Configuration is done in the head of the script.

EOF
}

error()
{
  if type zenity &>/dev/null; then
    zenity --error --ellipsize --text "$*"
  else
    echo "$*" 1>&2
  fi

  exit 1
}

send_json()
{
  curl \
  ${user:+--user "$user:$pass"} \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"Player.Open","params":{"item":{"file":"'"$1"'"}},"id":1}' \
  http://$host:$port/jsonrpc \
  || error "Failed to send link - is Kodi running?"
}

is_file()
{
  clean=$(echo $1 | sed 's/\\ / /g')
  if [[ -f $1 ]]; then
    echo $1
  elif [[ -f $clean ]]; then
    echo $clean
  fi
}

#ytplugin='plugin://plugin.video.youtube/?action=play_video&videoid='
ytplugin='plugin://plugin.video.sendtokodi/?https://youtube.com/watch?v='

[[ $host && $port ]] || error "Please set host and port in configuration"
[[ "$1" = --help ]] && show_help

clipboard=''
if type wl-paste &>/dev/null; then
  echo "current clipboard content: '$(wl-paste)'"
  if [[ "$(wl-paste)" =~ ^(https?|file):\/\/ ]]; then
    clipboard=$(wl-paste)
  elif [[ "$(wl-paste -p)" =~ ^(https?|file):\/\/ ]]; then
    clipboard=$(wl-paste -p)
  else
    clipboard=$(is_file "$(wl-paste)")
    if [[ ! $clipboard ]]; then
      clipboard=$(is_file "$(wl-paste -p)")
    fi
    if [[ ! $clipboard ]]; then
      clipboard=''
    fi
  fi
fi

# Dialog box?
input=$1
until [[ $input ]]; do
  input="$(zenity --entry --title "Send to Kodi" --text \
    "Paste a video link here" --entry-text "$clipboard")" || exit
done

if [[ $input =~ ^file:// ]]; then
  # Remove file:// and carrige return (\r) at the end
  input="$(sed 's%^file://%%;s/\r$//' <<< "$input")"
fi

# Get URL for...

# Local media
if [[ -e $input ]]; then
  type nc &>/dev/null || error "netcat required"
  [[ $local_hostname && $local_port ]] || \
    error "Please set local hostname and port in configuration"

  # Start netcat in background and kill it when we exit
  nc -lp $local_port < "$input" &
  trap "kill $!" EXIT

  url="tcp://$local_hostname:$local_port"

# youtube.com / youtu.be
elif [[ $input =~ ^https?://(www\.)?youtu(\.be/|be\.com/watch\?v=) ]]; then
  url="$ytplugin$(\
    sed 's/.*\(youtu\.be\/\|[&?]v=\)\([a-zA-Z0-9_-]\+\).*/\2/'\
    <<< "$input"\
  )"

# Playable formats
elif [[ $input =~ \.(mp4|mkv|mov|avi|flv|wmv|asf|mp3|flac|mka|m4a|aac|ogg|pls|jpg|png|gif|jpeg|tiff)(\?.*)?$ ]]; then
   url="$input"

# Youtube-dl
else
  type youtube-dl &>/dev/null || error "youtube-dl required"
  url="$(youtube-dl -gf best "$input")" || \
    error "No videos found, or site not supported by youtube-dl"
fi

[[ $url ]] && send_json "$url"

# Wait for netcat to exit
wait
# Don't kill netcat
trap - EXIT
