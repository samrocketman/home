#!/bin/sh
# Created by Sam Gleske
# Pop!_OS 22.04 LTS
# Linux 6.6.10-76060610-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)
#DESCRIPION
#  Prints a history of timestamps based on an interval with a customizable
#  format.  See --help for more information and usage examples.

set -e

#
# ENVIRONMENT VARIABLES
#

# 15-minute interval timestamps
#interval="15"

# number of timestamps in history to print
#timestamp_limit="1"

# Output format
#format="+%Y-%m-%d %H:%M:00"

# Outputs UTC timezone
#timezone="UTC"

# Shift time positive or negative minutes
#shift_minutes=0

#
# FUNCTIONS
#

default_environment() {
  if [ "x$interval" = x ]; then
    interval=15
  fi

  if [ "x$timestamp_limit" = x ]; then
    timestamp_limit=1
  fi

  if [ "x$format" = x ]; then
    format='+%Y-%m-%d %H:%M:00'
  fi

  if [ "x$timezone" = x ]; then
    timezone=UTC
  fi

  if [ "x$unix_timestamp" = x ]; then
    unix_timestamp="`date +%s`"
  fi
}

# Prints a history of one or more timestamps based on an interval within an
# hour.
print_interval_timestamp() {
  TZ="$timezone" date -d "@$1" "$format"
  if [ "$current_timestamp_iteration" -lt "$timestamp_limit" ]; then
    current_timestamp_iteration="$(( $current_timestamp_iteration + 1 ))"
    print_interval_timestamp "$(( $1 - $interval_seconds ))"
  fi
}

process_args() {
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
      -s|--shift)
        shift
        shift_minutes="$1"
        shift
        ;;
      --startsat)
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
        echo "See timestamper.sh --help" >&2
        exit 1
    esac
  done
}

helpdoc() {
cat >&2 <<EOF

timestamper.sh - A timestamping utility based on hourly intervals.

Prints a history of timestamps based on an interval with a customizable output
format based on strftime.

SYNOPSIS

  timstamper.sh [options ...]
  timestamper.sh [-f FORMAT] [-i INTERVAL] [-l LIMIT] \
    [--startsat UNIX_TIMESTAMP] [-s MINUTES] [-t TIMEZONE]

OPTIONS:
  -f FORMAT, --format FORMAT
    Customize the strftime FORMAT.  Customizes the format of the timestamp
    being printed.  Default: '+%Y-%m-%d %H:%M:00'

  -i INTERVAL, --interval INTERVAL
    Customize the nearest minute interval when calculating timestamps.
    Default: 15

  -l LIMIT, --limit-timestamps LIMIT
    Print more than one timestamp up to a LIMIT. Default: 1

  -s MINUTES, --shift MINUTES
    Number of MINUTES to shift the interval (can be positive or negative).  It
    only affects the initial INTERVAL offset followed by a normal INTERVAL.

  --startsat UNIX_TIMESTAMP
    Customize when to start calculating the history of timestamps from a
    starting UNIX_TIMESTAMP.  Default: current time

  -t TIMEZONE, --timezone TIMEZONE
    Customize the TIMEZONE for date utility when printing timestamps.
    Default: UTC.

ENVIRONMENT VARIABLES:
  format
    Customize the FORMAT.

  interval
    Customize the INTERVAL.

  shift_minutes
    Number of MINUTES to shift the interval (can be positive or negative).

  timestamp_limit
    Customize the LIMIT.

  timezone
    Customize the TIMEZONE.

  unix_timestamp
    Customize the UNIX_TIMESTAMP.

EXAMPLE

  timestamper.sh -i 5 -l 15 -t America/New_York -f '+%Y/%m/%d/%H/%M'

EOF
}

validate_args() {
  validation_result=0
  if ! positive_integer interval "$interval"; then
    validation_result=1
  fi
  if ! positive_integer timestamp_limit "$timestamp_limit"; then
    validation_result=1
  fi
  if ! positive_integer unix_timestamp "$unix_timestamp"; then
    validation_result=1
  fi
  if ! echo "$format" | grep '^+' > /dev/null 2>&1; then
    validation_error 'format must start with + and is a strftime format.' >&2
    validation_result=1
  fi
  if [ "$validation_result" = 1 ]; then
    echo 'Argument ERRORS were found.  See timestamper.sh --help' >&2
  fi
  return "$validation_result"
}

validation_error() {
  echo "    $1" >&2
  echo >&2
}

positive_integer() {
  if ! [ "$2" -gt 0 ]; then
    validation_error "$1 must be a positive integer."
    return 1
  fi
  return 0
}

#
# MAIN
#

if [ ! "`uname`" = Linux ]; then
  if ! type gdate > /dev/null 2>&1; then
    echo 'GNU date required.  Install via homebrew' >&2
    exit 1
  fi
  # alias date to gdate on MacOS
  date() { gdate "$@"; }
fi

process_args "$@"
default_environment
validate_args
interval_seconds="$(( $interval * 60 ))"
unix_timestamp="$(( $unix_timestamp - ( $unix_timestamp % $interval_seconds ) ))"
if ! [ "x$shift_minutes" = x ]; then
  shift_seconds="$(( $shift_minutes * 60 ))"
  unix_timestamp="$(( $unix_timestamp + $shift_seconds ))"
fi
current_timestamp_iteration=1
print_interval_timestamp "$unix_timestamp"
