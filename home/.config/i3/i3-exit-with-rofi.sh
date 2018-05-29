#!/usr/bin/env sh
set -eu

message='<big><b>Do you really want to exit i3?</b></big>'
options="\
Cancel
Exit
Restart
Shutdown"

answer="$(echo "$options" \
  | rofi -i -dmenu -width 100 -padding 400 -mesg "$message")"

case "$answer" in
  Cancel)
    # Nothing to do!
    ;;
  Exit)
    i3-msg exit
    ;;
  Restart)
    reboot
    ;;
  Shutdown)
    shutdown -hP now
    ;;
  *)
    echo "Invalid answer: $answer" >&2
    exit 1
    ;;
esac
