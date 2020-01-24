#!/usr/bin/env sh
# shellcheck disable=SC2039

print_usage() {
  local program="$1"
  local version="$2"
  local author="$3"

  echo "$program $version

    i3 workstation power and exiting.

    USAGE:
        $program [FLAGS] [<ACTION>]

    FLAGS:
        -d, --dialog    Displays a graphical dialog
        -h, --help      Prints this message
        -V, --version   Prints version information

    ARGS:
        <ACTION>    One of {cancel|exit|lock|suspend|hibernate|reboot|shutdown}

    AUTHOR:
        $author
    " | sed 's/^ \{1,4\}//g'
}

main() {
  set -eu
  if [ -n "${DEBUG:-}" ]; then set -x; fi
  if [ -n "${TRACE:-}" ]; then set -xv; fi

  local program version author
  program="$(basename "$0")"
  version="0.5.0"
  author="Fletcher Nichol <fnichol@nichol.ca>"

  # Parse CLI arguments and set local variables
  parse_cli_args "$program" "$version" "$author" "$@"
  local action="${ACTION:-}"
  local use_dialog="${USE_DIALOG:-}"
  unset ACTION USE_DIALOG

  if [ -n "$use_dialog" ]; then
    show_dialog
  else
    run_action "$action"
  fi
}

parse_cli_args() {
  local program version author
  program="$1"
  shift
  version="$1"
  shift
  author="$1"
  shift

  OPTIND=1
  # Parse command line flags and options
  while getopts ":hdV-:" opt; do
    case $opt in
      d)
        USE_DIALOG=true
        ;;
      h)
        print_usage "$program" "$version" "$author"
        exit 0
        ;;
      V)
        print_version "$program" "$version"
        exit 0
        ;;
      -)
        case "$OPTARG" in
          dialog)
            USE_DIALOG=true
            ;;
          help)
            print_usage "$program" "$version" "$author"
            exit 0
            ;;
          version)
            print_version "$program" "$version" "true"
            exit 0
            ;;
          '')
            # "--" terminates argument processing
            break
            ;;
          *)
            print_usage "$program" "$version" "$author" >&2
            die "invalid argument --$OPTARG"
            ;;
        esac
        ;;
      \?)
        print_usage "$program" "$version" "$author" >&2
        die "invalid option: -$OPTARG"
        ;;
    esac
  done
  # Shift off all parsed token in `$*` so that the subcommand is now `$1`.
  shift "$((OPTIND - 1))"

  if [ -n "${1:-}" ]; then
    ACTION="$1"
  fi

  if [ -n "${ACTION:-}" ] && [ -n "${USE_DIALOG:-}" ]; then
    print_usage "$program" "$version" "$author" >&2
    die "cannot provide action and use dialog"
  fi
  if [ -z "${ACTION:-}" ] && [ -z "${USE_DIALOG:-}" ]; then
    print_usage "$program" "$version" "$author" >&2
    die "must provide either action or use dialog"
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

  need_cmd tr
  need_cmd wc

  lines=$(echo "$options" | wc -l)
  action="$(echo "$options" | dialog "$lines" -mesg "$message")"

  run_action "$(echo "$action" | tr '[:upper:]' '[:lower:]')"
}

dialog() {
  local lines="$1"
  local message="$2"

  need_cmd bemenu

  bemenu --ignorecase --list "$lines" --prompt "$message"
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
      print_usage
      die "invalid action: $action"
      ;;
  esac
}

check_cmd() {
  local _cmd
  _cmd="$1"

  if ! command -v "$_cmd" >/dev/null 2>&1; then
    unset _cmd
    return 1
  else
    unset _cmd
    return 0
  fi
}

die() {
  local _msg
  _msg="$1"

  case "${TERM:-}" in
    *term | xterm-* | rxvt | screen | screen-*)
      printf -- "\n\033[1;31;40mxxx \033[1;37;40m%s\033[0m\n\n" "$_msg" >&2
      ;;
    *)
      printf -- "\nxxx %s\n\n" "$_msg" >&2
      ;;
  esac

  unset _msg
  exit 1
}

need_cmd() {
  local _cmd
  _cmd="$1"

  if ! check_cmd "$_cmd"; then
    die "Required command '$_cmd' not found on PATH"
  fi

  unset _cmd
  return 0
}

main "$@" || exit 99
