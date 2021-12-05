#!/bin/bash
# Created by Sam Gleske
# Mon Nov 29 21:34:28 EST 2021
# MIT License - https://github.com/samrocketman/home
# Inspired by travis_wait script but better.
set -eo pipefail

function helpdoc() {
cat <<EOF
${0##*/} - a command to run other commands with reduced log output.

SYNOPSIS:

  ${0##*/} [OPTIONS] [--] COMMAND

DESCRIPTION:
  Run a command with reduced log output.  This will execute the command and
  hide log output.  The script will output a short status every 30 seconds.  If
  the command being executed exits with an error, then the stderr log from the
  command is printed along with the overall exit status.

ARGUMENTS:
  COMMAND
    A command to run with reduced log output.  The COMMAND can be a single word
    or be a command with all of its options to be run.  Quoting is preserved
    when passing options to the COMMAND.

OPTIONS:
  --
    Stop processing options.  All following options will belong to the COMMAND.
    It is recommended to always pass this option so that command arguments are
    not accidentally mixed with the arguments in this list.

  -h, --help
    Show help.

  -d, --debug-bundle
    Create a debug bundle archive which contains the full contents of stdout
    and stderr log.  These logs are the output of the COMMAND being executed.
    It will create a tar.gz file in the current working directory.
    Default: Disabled by default.

  -b, --no-background-status
    While executing a command, a short status phrase will be printed every 30
    seconds.  This option disables the behavior and hides all output during
    execution.
    Default: Background status is enabled by default.

  -c, --combined-log
    Combine stdout and stderr into a single in-line log.  This means -l stderr
    has no effect since stdout and stderr logs are combined.
    Default: Logs are split separately between stdout and stderr.

  -e, --hide-errors
    This option will hide any errors which would occur.  If an error occurs,
    then no exit status will be printed and no stderr log will be printed.
    However, the script will still exit non-zero.
    Default: Errors on exit are shown by default.

  -E, --extended-regexp
    Modifies behavior of --status-logfile-regexp option.  Enables extended grep
    patterns for --status-logfile-regexp option.
    Default: Disabled by default.

  -g EXPR, --status-logfile-regexp EXPR
    When using a --background-status-logfile, this will limit the output of the
    log entry using the 'grep -o EXPR' command.  The background status message
    will include a filtered partial output printed from the
    --background-status-logfile.  It will find the last 50 lines in the log
    file and output based on the user provided EXPR.  This option is only
    effective when --background-status-logfile is provided.
    Default: '${log_filter_expr}'

  -i INTERVAL, --background-interval INTERVAL
    Customize the INTERVAL for how often the --status-phrase is printed while
    executing the COMMAND.  The INTERVAL is in seconds.
    Default: ${background_interval}

  -l LOGFILE, --background-status-logfile LOGFILE
    When a status phrase is printed every 30 seconds it can also be paired with
    an entry from the LOGFILE.  There's two special LOGFILEs.
      * stdout - If LOGFILE is 'stdout', then the log is derived from the
                 COMMAND stdout output.
      * stderr - If LOGFILE is 'stderr', then the log is derived from the
                 COMMAND stderr output.
    Otherwise, the LOGFILE will be read as a normal file to determine status
    entries.
    Default: Disabled by default.

  -r TIMES, --retry TIMES
    Number of TIMES to retry the command if it fails.  TIMES is a number
    greater than 0.
    Default: Runs once.

  -R INTERVAL, --retry-sleep INTERVAL
    Time INTERVAL to wait between a failed command and when it retries again
    with --retry option. INTERVAL is a number greater than 0.  This option is
    only effective when paired with the --retry option.
    Default: No wait.

  -s PHRASE, --status-phrase PHRASE
    Every 30 seconds output a PHRASE as a short execution status.  The PHRASE
    may be paired with an entry or partial entry from a log file provided by
    --background-status-logfile.
    Default: '${status_phrase}'

EXAMPLE:
  A harmless example executing a sleep.
    ${0##*/} -i 5 -- sleep 11

  Limit execution within a timeout.

    timeout 1 ${0##*/} -- sleep 11

  Run a maven build.
    ${0##*/} -- mvn clean verify

  Run a maven build and generate a debug bundle for extra troubleshooting.
    ${0##*/} --debug-bundle -- mvn clean verify

  Alternate shorthand usage of creating a debug bundle.
    ${0##*/} -d -- mvn clean verify

  Run a program while showing a partial output of its stderr log.
    ${0##*/} -l stderr -g '^Done \[[^]]\+\]' -- ./some-advanced-script.sh

  Minimal output.  The following will hide errors and disable the background
  status update.
    ${0##*/} -e -b -- go build
EOF
}

# usage: echo_stdout 'hello world'
function echo_stdout() {
  if [ "${early_exit:-true}" = true ]; then
    echo "$*"
  else
    echo "$*" >&3
  fi
}

# usage: echo_stderr 'hello world'
function echo_stderr() {
  if [ "${early_exit:-true}" = true ]; then
    echo "$*" >&2
  else
    echo "$*" >&4
  fi
}

# usage: echo 'hello world' | piped_stdout
function piped_stdout() {
  if [ "${early_exit:-true}" = true ]; then
    cat
  else
    cat >&3
  fi
}

# usage: echo 'hello world' | piped_stderr
function piped_stderr() {
  if [ "${early_exit:-true}" = true ]; then
    cat >&2
  else
    cat >&4
  fi
}

function command_status() {
  grep_opts=( -o )
  if [ "${extended_regexp}" = true ]; then
    grep_opts+=( -E )
  fi
  [ ! -f "${background_status_logfile:-}" ] ||
    tail -n50 "${background_status_logfile:-}" | \
    grep "${grep_opts[@]}" -- "${log_filter_expr}" | tail -n1 || echo
}

function background_status() (
  while true; do
    sleep "${background_interval:-30}"
    if [ ! -d "${TMP_DIR:-}" ]; then
      break
    fi
    if [ ! -f "${background_status_logfile:-}" ]; then
      echo_stdout "${status_phrase}"
    else
      echo_stdout "${status_phrase} $(command_status)"
    fi
  done
)

function cleanup_on() {
  set +exo pipefail
  if [ "$1" -ne 0 ]; then
    # exited with error
    if [ "${show_error_on_failure}" = true ]; then
      if [ "${combined_log:-false}" = true ]; then
        piped_stderr < "${TMP_DIR:-}"/stdout
      else
        piped_stderr < "${TMP_DIR:-}"/stderr
      fi
      echo_stderr "ERROR Exit code: $1"
    fi
  fi
  if [ "${debug_bundle}" = true ]; then
    archive=debug_bundle_"$(date +%s)".tar.gz
    echo_stderr "Creating debug bundle... '${archive}'"
    (
      pushd "${TMP_DIR}" &> /dev/null
      tar -czf ~1/"${archive}" *
    )
    if [ ! -f "${archive}" ]; then
      echo_stderr "Something went wrong.  Could not create archive '${archive}'"
    fi
  fi
  [ ! -d "${TMP_DIR:-}" ] || rm -rf "${TMP_DIR:-}"
  # early exit is to prevent the script being killed prematurely during option
  # processing.
  # This affects running a command like: reduced-log-run.sh --help | less
  if [ "${early_exit}" = false ] && [ "${background_status}" = true ]; then
    signal_exit SIGTERM
  fi
}

function signal_exit() {
  set +x
  # flag is to prevent recursive kill being called
  if [ "${flag:-false}" = "$1" ]; then
    return
  fi
  flag="$1"
  kill -s $1 0
}

#
# INITIAL trap setup
#
TMP_DIR="$(mktemp -d)"
for signal in SIGHUP SIGINT SIGTERM; do
  trap "signal_exit ${signal}" "${signal}"
done
trap 'cleanup_on $?' EXIT

#
# Process arguments
#
cmd_line=()
background_interval=30
background_status=true
background_status_logfile=''
combined_log=false
debug_bundle=false
early_exit=true
extended_regexp=false
log_filter_expr='.*'
retry=0
retry_sleep=0
show_error_on_failure=true
status_phrase='Command in progress...'
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_error_on_failure=false
      helpdoc | piped_stdout
      exit 1
      ;;
    -b|--no-background-status)
      background_status=false
      shift
      ;;
    -c|--combined-log)
      combined_log=true
      if [ "${background_status_logfile:-}" = "$TMP_DIR"/stderr ]; then
        background_status_logfile="$TMP_DIR"/stdout
      fi
      shift
      ;;
    -d|--debug-bundle)
      debug_bundle=true
      shift
      ;;
    -e|--hide-errors)
        show_error_on_failure=false
        shift
      ;;
    -E|--extended-regexp)
      extended_regexp=true
      shift
      ;;
    -g|--status-logfile-regexp)
      log_filter_expr="$2"
      shift
      shift
      ;;
    -i|--background-interval)
      if ! grep -- '^[0-9]\+' <<< "${2}" &> /dev/null ||
        [ ! "${2}" -gt 0 ]; then
        show_error_on_failure=false
        echo_stderr '-i|--background-interval option must be a number greater than 0.'
        echo_stderr "See also: ${0##*/} --help"
        exit 1
      fi
      background_interval="$2"
      shift
      shift
      ;;
    -l|--background-status-logfile)
      if [ "$2" = stdout ] ||
        [ "${combined_log:-false}" = true -a "$2" = stdout ]; then
        background_status_logfile="$TMP_DIR"/stdout
      elif [ "$2" = stderr ]; then
        background_status_logfile="$TMP_DIR"/stderr
      else
        background_status_logfile="$2"
      fi
      shift
      shift
      ;;
    -r|--retry)
      if ! grep -- '^[0-9]\+' <<< "${2}" &> /dev/null ||
        [ ! "${2}" -gt 0 ]; then
        show_error_on_failure=false
        echo_stderr '-r|--retry option must be a number greater than 0.'
        echo_stderr "See also: ${0##*/} --help"
        exit 1
      fi
      retry="$2"
      shift
      shift
      ;;
    -R|--retry-sleep)
      if ! grep -- '^[0-9]\+' <<< "${2}" &> /dev/null ||
        [ ! "${2}" -gt 0 ]; then
        show_error_on_failure=false
        echo_stderr '-R|--retry-sleep option must be a number greater than 0.'
        echo_stderr "See also: ${0##*/} --help"
        exit 1
      fi
      retry_sleep="$2"
      shift
      shift
      ;;
    -s|--status-phrase)
      status_phrase="$2"
      shift
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done
if [ "$#" -gt 0 ]; then
  cmd_line+=( "$@" )
fi
if [ "${combined_log:-false}" = true ]; then
  exec 3>&1 4>&2 > "$TMP_DIR"/stdout 2>&1
else
  exec 3>&1 4>&2 > "$TMP_DIR"/stdout 2> "$TMP_DIR"/stderr
fi
early_exit=false


#
# Execute command in silence...
#
if [ "${#cmd_line[@]}" -eq 0 ]; then
  echo_stderr 'No COMMAND provided.'
  exit 1
fi

echo_stdout "Running command: ${cmd_line[*]}"
if [ "${background_status}" = true ]; then
  background_status &
fi
if [ "${retry}" -gt 0 ]; then
  # Subshell is necessary to properly abort the script when 'kill 0' is called.
  (
    set -x
    until "${cmd_line[@]}"; do
      status=$?
      set +x
      if [ "${retry}" -eq 0 ]; then
        exit "${status}"
      fi
      (( retry=retry-1 ))
      if [ "${retry_sleep}" -gt 0 ]; then
        sleep "${retry_sleep}"
      fi
      echo_stdout "Retry command: ${cmd_line[*]}"
      set -x
    done
  )
else
  set -x
  "${cmd_line[@]}"
fi
