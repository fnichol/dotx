#!/usr/bin/env sh

main() {
  set -eu
  if [ -n "${DEBUG:-}" ]; then set -x; fi

  _program="$(basename "$0")"
  _version="0.5.0"
  _author="Fletcher Nichol <fnichol@nichol.ca>"

  parse_cli_args "$@"

  if [ -n "${_use_dialog:-}" ]; then
    show_dialog
  else
    run_action "$_action"
  fi
}

print_help() {
  cat<<HELP
$_program $_version

$_author

i3 workstation power and exiting.

USAGE:
        $_program [FLAGS] [<ACTION>]

FLAGS:
    -h  Prints this message
    -d  Display a graphical dialog

ARGS:
    <ACTION>    One of {cancel|exit|lock|suspend|hibernate|reboot|shutdown}

HELP
}

parse_cli_args() {
  OPTIND=1
  # Parse command line flags and options
  while getopts ":hd" opt; do
    case $opt in
      h)
        print_help
        exit 0
        ;;
      d)
        _use_dialog=true
        ;;
      \?)
        print_help
        exit_with "Invalid option:  -$OPTARG" 1
        ;;
    esac
  done
  # Shift off all parsed token in `$*` so that the subcommand is now `$1`.
  shift "$((OPTIND - 1))"

  if [ -n "${1:-}" ]; then
    _action="$1"
  fi

  if [ -n "${_action:-}" ] && [ -n "${_use_dialog:-}" ]; then
    print_help
    exit_with "Cannot provide action and use dialog" 2
  fi
  if [ -z "${_action:-}" ] && [ -z "${_use_dialog:-}" ]; then
    print_help
    exit_with "Must provide either action or use dialog" 2
  fi
}

exit_with() {
  case "${TERM:-}" in
    *term | xterm-* | rxvt | screen | screen-*)
      printf -- "\n\033[1;31mERROR: \033[1;37m${1:-}\033[0m\n\n" >&2
      ;;
    *)
      printf -- "\nERROR: ${1:-}\n\n" >&2
      ;;
  esac
  exit "${2:-10}"
}

need_cmd() {
  if ! command -v "$1" > /dev/null 2>&1; then
    exit_with "Required command '$1' not found on PATH" 127
  fi
}

show_dialog() {
  local lines action
  local message='<big><b>i3 Exit Options</b></big>'
  local options="\
Cancel
Exit
Lock
Suspend
Hibernate
Reboot
Shutdown"

  need_cmd rofi
  need_cmd tr
  need_cmd wc

  lines=$(echo "$options" | wc -l)
  action="$(echo "$options" | rofi -i -dmenu -lines "$lines" -mesg "$message")"

  run_action "$(echo "$action" | tr '[:upper:]' '[:lower:]')"
}

run_action() {
  local action="$1"

  case "$action" in
    cancel)
      # Nothing to do!
      ;;
    exit)
      need_cmd i3-msg

      i3-msg exit
      ;;
    lock)
      need_cmd i3lock

      i3lock
      ;;
    suspend)
      need_cmd i3lock
      need_cmd systemctl

      i3lock
      systemctl suspend
      ;;
    hibernate)
      need_cmd i3lock
      need_cmd systemctl

      i3lock
      systemctl hibernate
      ;;
   reboot)
      need_cmd systemctl

      systemctl reboot
      ;;
    shutdown)
      need_cmd systemctl

      systemctl poweroff --ignore-inhibitors
      ;;
    *)
      print_help
      exit_with "Invalid action: $action" 3
      ;;
  esac
}

main "$@" || exit 99
