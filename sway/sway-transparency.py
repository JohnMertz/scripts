#!/usr/bin/env python3

# This script requires i3ipc-python package (install it from a system package manager
# or pip).
# It makes inactive windows transparent. Use `transparency_val` variable to control
# transparency strength in range of 0…1 or use the command line argument -o.

import argparse
import i3ipc
import signal
import sys
import os
import time
from pathlib import Path
from functools import partial

def on_window_focus(opacity, ipc, event):
  if os.path.exists(flag):
    return
  global prev_focused
  global prev_workspace
  # Refresh previous window in case it changed while in focus
  if prev_focused:
    prev_focused = ipc.get_tree().find_by_id(prev_focused.id)

  focused_workspace = ipc.get_tree().find_focused()

  if focused_workspace == None:
    return

  focused = event.container
  workspace = focused_workspace.workspace().num

  if prev_focused == None or focused.id != prev_focused.id:  # https://github.com/swaywm/sway/issues/2859
    focused.command("opacity 1")
    if prev_focused and workspace == prev_workspace and not (prev_focused.floating == "user_on" and prev_focused.sticky):
      prev_focused.command("opacity " + opacity)
    prev_focused = focused
    prev_workspace = workspace

def show_hide(ipc, opacity):
  global flag
  if os.path.exists(flag):
    os.remove(flag)
  else:
    opacity = 0
    Path(flag).touch()
  for workspace in ipc.get_tree().workspaces():
    for w in workspace:
      if w.focused:
        w.command("opacity 1")
      else:
        w.command("opacity "+str(opacity))

def fade(ipc, opacity):
  global flag
  if os.path.exists(flag):
    show_hide(ipc, opacity)
    return
  for i in range(1,100):
    for workspace in ipc.get_tree().workspaces():
      for w in workspace:
        if w.focused:
          w.command("opacity "+str(1-(i/100)))
        elif float(opacity) * 100 >= i:
          w.command("opacity "+str(float(opacity)-(i/100)))
    time.sleep(0.01)
  for workspace in ipc.get_tree().workspaces():
    for w in workspace:
      w.command("opacity 0")
  Path(flag).touch()

def remove_opacity(ipc):
  global pid
  global flag
  for workspace in ipc.get_tree().workspaces():
    for w in workspace:
      w.command("opacity 1")
  for file in [pid, flag]:
    if os.path.exists(file):
      os.remove(file)
  ipc.main_quit()
  sys.exit(0)

def set_all(ipc,opacity):
  for window in ipc.get_tree():
    if prev_focused.floating == "user_on" and prev_focused.sticky:
      window.command("opacity 1")
    else:
      window.command("opacity " + opacity)

flag = os.environ["HOME"]+"/.local/state/sway-hidden"
pid = os.environ["HOME"]+"/.local/state/sway-transparency"
opacity = "0.85"

if __name__ == "__main__":
  f = open(pid, "w")
  try:
    f.write(str(os.getpid()))
  except AssertionError as error:
    print("Failed to write PID to file "+pid+": "+error)
    sys.exit(0)
  f.close()

  parser = argparse.ArgumentParser(
    description="This script allows you to set the transparency of unfocused windows in sway."
  )
  parser.add_argument(
    "--opacity",
    "-o",
    type=str,
    default=opacity,
    help="set opacity value in range 0...1",
  )
  args = parser.parse_args()

  ipc = i3ipc.Connection()
  prev_focused = None
  prev_workspace = ipc.get_tree().find_focused().workspace().num

  for window in ipc.get_tree():
    if window.focused:
      prev_focused = window
    elif window.floating == "user_on" and window.sticky:
      continue
    else:
      window.command("opacity " + args.opacity)
  for sig in [signal.SIGINT, signal.SIGTERM]:
    signal.signal(sig, lambda signal, frame: remove_opacity(ipc))
  signal.signal(signal.SIGUSR1, lambda signal, frame: show_hide(ipc, opacity))
  signal.signal(signal.SIGUSR2, lambda signal, frame: fade(ipc, opacity))
  ipc.on("window::focus", partial(on_window_focus, args.opacity))
  ipc.main()

