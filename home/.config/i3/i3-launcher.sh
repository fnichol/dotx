#!/usr/bin/env sh
# shellcheck disable=SC2039

print_usage() {
  local program="$1"
  local version="$2"
  local author="$3"

  echo "$program $version

    i3 program launcher

    USAGE:
        $program [FLAGS] [<ACTION>]

    FLAGS:
        -h, --help      Prints this message
        -V, --version   Prints version information

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

  need_cmd compgen
  need_cmd fzf
  need_cmd i3-msg
  need_cmd sort
  need_cmd xargs

  show_dialog
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
  while getopts ":hV-:" opt; do
    case $opt in
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
}

show_dialog() {
  compgen -c \
    | sort -u \
    | fzf --no-extended --layout=reverse --margin=33%,25% --prompt="Launch: " \
    | xargs -I"{}" i3-msg "exec --no-startup-id {}"
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
