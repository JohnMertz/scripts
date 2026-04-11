#!/bin/bash

FADE_TIMEOUT=60        # one minute
DIM_TIMEOUT=120        # two minutes
LOCK_TIMEOUT=300       # five minutes
SLEEP_TIMEOUT=600      # ten minutes
HIBERNATE_TIMEOUT=3600 # one hour

BLFILE="$HOME/.local/state/last_brightness"
DNDSTATE="$HOME/.local/state/do-not-disturb"
POWERMODE="$HOME/.local/state/power_profile"
OPFILE="$HOME/.local/state/active_outputs"
MODEFILE="$HOME/.local/state/idle_mode"
IDLEMODE=$(cat $MODEFILE)
LASTFILE="$HOME/.local/state/idle_last"
CURRENT="$HOME/.local/state/idle_current"

if [[ -n $2 ]]; then
  if [[ $2 == '--ignore_mode' ]]; then
    IDLEMODE='hibernate'
  elif [[ $1 == "mode" ]]; then
    IDLEMODE=$2
  else
    echo "Unknown mode $IDLEMODE"
    exit
  fi
fi
if [[ -z $IDLEMODE ]]; then
  IDLEMODE="lock"
fi

function modetonum() {
  if [[ $1 == 'none' ]]; then
    echo 0
  elif [[ $1 == 'fade' ]]; then
    echo 1
  elif [[ $1 == 'dim' ]]; then
    echo 2
  elif [[ $1 == 'lock' ]]; then
    echo 3
  elif [[ $1 == 'sleep' ]]; then
    echo 4
  elif [[ $1 == 'hibernate' ]]; then
    echo 5
  else
    echo "Invalid idle_mode '$1'"
    exit
  fi
}

function usage() {
  echo "usage: $0 <option> [--ignore_mode]
    start       - Initialize 'swayidle' script. This should be declared in Sway config
    stop        - Kill 'swayidle' script. Consider idle-inhibitor or sleepmode 'none' instead
    status      - What state of idle are we in right now
    daemon      - Run 'start' as a presistent background process
    mode <mode> - Set the idle_mode: none, fade, dim, lock, sleep, hibernate
    toggle      - Set the idle_mode to none, or restore last non-none mode
    fade        - First idle action. Fades all windows to show background
    unfade      - Restore opacity for faded windows
    dim         - Reduce display brightness to minimum
    undim       - Restore brightness to level prior to 'dim'
    lock        - Mark as inactive and start 'swaylock'
    unlock      - (Run upon unlock) Mark as active again
    sleep       - Disable displays, but continue background processes
    unsleep     - Re-enable displays
    hibernate   - Enter suspend-then-hibernate target
    unhibernate - Clean up after waking from hibernation
    help        - This message

    Idle will result in the following actions in sequence:

    fade        - 1 minute. Fade all windows by reducing opacity to 0 via Sway IPC. Sleep keyboard backlight.
    dim         - 2 minutes. Dim the display with \`gammactl\`
    lock        - 5 minutes. Lock the screen with \`swaylock\`
    sleep       - 10 minutes. Sleep by disabling power to all displays via DPMS
    hibernate   - 60 minutes. Hibernate by entering 'suspend-then-hibernate.target'

    Timeouts define statically in the program.

    Idle modes are additive, thus the idle_mode is the final action you would like to run in the 
    sequence. For example: 'sleep' mode will enable 'fade', 'lock', and 'sleep', but not 'hibernate'

    --ignore_mode   - Run <option> even if in a lower mode in the sequence
    "
  exit
}

echo $1
if [[ -z $1 ]]; then
  echo "Missing argument"
  usage
elif [[ $1 == "toggle" ]]; then
  if [[ -e $LASTFILE ]]; then
    LASTMODE=$(cat $LASTFILE)
    echo -n $LASTMODE > $MODEFILE
    rm $LASTFILE
  else
    echo -n $IDLEMODE > $LASTFILE
    echo -n none > $MODEFILE
  fi
elif [[ $1 == "mode" ]]; then
  if [[ -n $2 ]]; then
    echo -n $2 > $MODEFILE
  elif [[ -e $LASTFILE ]]; then
    LASTMODE=$(cat $LASTFILE)
    echo -n $LASTMODE > $MODEFILE
    rm $LASTFILE
  elif [[ $$IDLEMODE == 'none' ]]; then
    echo -n 'fade' > $MODEFILE
  elif [[ $IDLEMODE == 'fade' ]]; then
    echo -n 'dim' > $MODEFILE
  elif [[ $IDLEMODE == 'dim' ]]; then
    echo -n 'lock' > $MODEFILE
  elif [[ $IDLEMODE == 'lock' ]]; then
    echo -n 'sleep' > $MODEFILE
  elif [[ $IDLEMODE == 'sleep' ]]; then
    echo -n 'hibernate' > $MODEFILE
  elif [[ $IDLEMODE == 'hibernate' ]]; then
    echo -n 'fade' > $MODEFILE
  fi
elif [[ $1 == "-h" ]] || [[ $1 == "--help" ]] || [[ $1 == "help" ]]; then
  usage
elif [[ $1 == "start" ]]; then
  swayidle -w \
    timeout $FADE_TIMEOUT "$0 fade" \
    resume "$0 unfade" \
    timeout $DIM_TIMEOUT "$0 dim" \
    resume "$0 undim" \
    timeout $LOCK_TIMEOUT "$0 lock" \
    resume "$0 unlock" \
    timeout $SLEEP_TIMEOUT "$0 sleep" \
    resume "$0 unsleep" \
    timeout $HIBERNATE_TIMEOUT "$0 hibernate" \
    resume "$0 unhibernate"
  echo -n "awake" >$CURRENT
elif [[ $1 == "daemon" ]]; then
  nohup $0 start 2>/dev/null &
  echo -n "awake" >$CURRENT
elif [[ $1 == "stop" ]]; then
  pkill swayidle
  echo -n "stopped" >$CURRENT
elif [[ $1 == "status" ]]; then
  cat $CURRENT
  exit
elif [[ $1 == "fade" ]]; then
  echo $(modetonum $IDLEMODE)
  if [[ $(modetonum $IDLEMODE) -gt 0 ]]; then
    ${HOME}/scripts/thinkpad/kbd_backlight.pl sleep
    if [[ ! -e $HOME/.local/state/sway-hidden ]]; then
      kill -USR2 $(cat $HOME/.local/state/sway-transparency)
      swaync-client -D >$DNDSTATE
      swaync-client -dn
    fi
  fi
  echo -n "fade" >$CURRENT
elif [[ $1 == "unfade" ]]; then
  if [[ -e $HOME/.local/state/sway-hidden ]]; then
    kill -USR2 $(cat $HOME/.local/state/sway-transparency)
    [[ $(cat $DNDSTATE) == false ]] && swaync-client -df
  fi
  ${HOME}/scripts/thinkpad/kbd_backlight.pl restore
  echo -n "awake" >$CURRENT
elif [[ $1 == "dim" ]]; then
  if [[ $(modetonum $IDLEMODE) -gt 1 ]]; then
    brightnessctl -P -d 'intel_backlight' get >$BLFILE
    brightnessctl -q -d 'intel_backlight' set 1
  fi
  echo -n "dim" >$CURRENT
elif [[ $1 == "undim" ]]; then
  brightnessctl -q -d 'intel_backlight' set $(cat $BLFILE)%
  echo -n "unfade" >$CURRENT
elif [[ $1 == "lock" ]]; then
  if [[ $(modetonum $IDLEMODE) -gt 2 ]]; then
    swaylock -f -c 00000000
  fi
  echo -n "lock" >$CURRENT
elif [[ $1 == "unlock" ]]; then
  kill -USR1 $(pgrep swaylock)
  echo -n "undim" >$CURRENT
elif [[ $1 == "sleep" ]]; then
  if [[ $(modetonum $IDLEMODE) -gt 3 ]]; then
    powerprofilesctl get > $POWERMODE
    powerprofilesctl set power-saver
    for i in $(cat $OPFILE); do swaymsg "output $i dpms off"; done
  fi
  echo -n "sleep" >$CURRENT
elif [[ $1 == "unsleep" ]]; then
  for i in $(cat $OPFILE); do swaymsg "output $i dpms on"; done
  cd $HOME/scripts/sway
  source $HOME/.dotfiles/bash/plenv-path.sh
  $HOME/scripts/sway/displays.pl 2>&1 >$HOME/.local/state/display_unsleep
  powerprofilesctl set $(cat $POWERMODE)
  echo -n "unlock" >$CURRENT
elif [[ $1 == "hibernate" ]]; then
  if [[ $(modetonum $IDLEMODE) -gt 4 ]]; then
    sudo systemctl suspend-then-hibernate.target
  fi
  echo -n "unsleep" >$CURRENT
else
  echo "Invalid argument: $1"
  usage
fi
