#!/bin/bash
# Created by Sam Gleske
# Ubuntu 22.04.4 LTS
# Linux 6.5.0-28-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)
#DESCRIPION
#  Prints a history of timestamps based on an interval with a customizable
#  format.  See --help for more information and usage examples.
set -euo pipefail

#
# ENVIRONMENT VARIABLES
#

# 15-minute interval timestamps
interval="${interval:-15}"

# number of timestamps in history to print
timestamp_limit="${timestamp_limit:-1}"

format="${format:-+%Y-%m-%d %H:%M:00}"

# Outputs UTC timezone
timezone="${timezone:-UTC}"

#
# FUNCTIONS
#

# Prints a history of one or more timestamps based on an interval within an
# hour.
function print_interval_timestamp() {
  local current_timestamp="$(( $1 - ( $1 % interval_seconds ) ))"
  TZ="$timezone" date -d "@$current_timestamp" "$format"
  if [ "$current_timestamp_iteration" -lt "$timestamp_limit" ]; then
    current_timestamp_iteration="$(( $current_timestamp_iteration + 1 ))"
    print_interval_timestamp "$(( current_timestamp - interval_seconds ))"
  fi
}

function process_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help)
        helpdoc
        exit 1
        ;;
      -l|--limit-timestamps)
        shift
        timestamp_limit="$1"
        shift
        ;;
      -f|--format)
        shift
        format="$1"
        shift
        ;;
      -i|--interval)
        shift
        interval="$1"
        shift
        ;;
      -s|--startsat)
        shift
        unix_timestamp="$1"
        shift
        ;;
      -t|--timezone)
        shift
        timezone="$1"
        shift
        ;;
      *)
        echo 'Unsupported argument: '"$1" >&2
        echo "See ${0##*/} --help" >&2
        exit 1
    esac
  done
}

function helpdoc() {
cat >&2 <<EOF

${0##*/} - A timestamping utility based on hourly intervals.

Prints a history of timestamps based on an interval with a customizable format.

SYNOPSIS

  ${0##*/} [-f FORMAT] [-i INTERVAL] [-l LIMIT] [-s UNIX_TIMESTAMP] [-t TIMEZONE]

OPTIONS:
  -f FORMAT, --format FORMAT
    Customize the GNU date timestamp format.  Customizes the format of the
    timestamp being printed.  Default: '+%Y-%m-%d %H:%M:00'

  -i INTERVAL, --interval INTERVAL
    Customize the nearest interval a timestamp should be calculated against.
    Default: 15

  -l LIMIT, --limit-timestamps LIMIT
    Print more than one timestamp up to a LIMIT. Default: 1

  -s UNIX_TIMESTAMP, --startsat UNIX_TIMESTAMP
    Customize when to start calculating the history of timestamps from a
    starting UNIX_TIMESTAMP.  Default: current time

  -t TIMEZONE, --timezone TIMEZONE
    Customize the TZ timezone for GNU date.  Default: UTC.

ENVIRONMENT VARIABLES:
  format
    Customize the FORMAT.

  interval
    Customize the INTERVAL.

  timestamp_limit
    Customize the LIMIT.

  unix_timestamp
    Customize the UNIX_TIMESTAMP.

  timezone
    Customize the TIMEZONE.

EXAMPLE

  ${0##*/} -i 5 -l 15 -t America/New_York -f '+%Y/%m/%d/%H/%M'

EOF
}

function validate_args() {
  local errors=()
  local val
  for x in interval timestamp_limit unix_timestamp; do
    val="$(eval "echo \${${x}:-}")"
    if ! [ "$val" -gt 0 ] &> /dev/null; then
      errors+=( "$x must be a positive integer." )
    fi
  done
  if ! grep '^+' <<< "$format" &> /dev/null; then
    errors+=( 'format must start with + and is a GNU date format.' )
  fi
  if [ "${#errors[@]}" -gt 0 ]; then
    echo 'The following argument ERRORS were found:' >&2
    echo >&2
    for err in "${errors[@]}"; do
      echo "    $err" >&2
      echo >&2
    done
    echo "See ${0##*/} --help" >&2
    exit 1
  fi
}

#
# MAIN
#

# Homebrew compatibility on Mac
if [ ! "$(uname)" = Linux ]; then
  if ! type -P gdate >& /dev/null; then
    echo 'GNU date required.  Install via homebrew' >&2
    exit 1
  fi
  # alias date to gdate on MacOS
  date() { gdate "$@"; }
fi

process_args "$@"

interval_seconds="$(( interval * 60 ))"

if [ -z "${unix_timestamp:-}" ]; then
  unix_timestamp="$(date +%s)"
fi

export interval timestamp_limit unix_timestamp
validate_args

# pass current unix timestamp to guarantee time consistency
current_timestamp_iteration=1
# All internal calculation performed in UTC timezone.
export TZ="UTC"
print_interval_timestamp "${unix_timestamp}"
