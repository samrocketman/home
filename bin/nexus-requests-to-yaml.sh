#!/bin/bash
# Created by Sam Gleske
# Tue Jan 20 21:49:46 EST 2026
# MIT Licensed - Copyright 2026 Sam Gleske - https://github.com/samrocketman
# DESCRIPTION
#   Processes a Sonatype Nexus request log and attempts to make sense of a
#   large volume of requests.  Intended to help track down sources of request
#   load spikes (amount and data).
#
#   Converts a Sonatype Nexus request log into YAML.
#   See --help for more details and options.
# REQUIREMENTS
#   BSD or GNU coreutils
#   BSD or GNU awk
#   jq - https://jqlang.org/
#   yq - https://github.com/mikefarah/yq
#   Python 2.7 or higher
set -euo pipefail
export TMP_DIR
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

missing=( )
for x in awk cat dd grep jq sed yq; do
  if ! type -P "$x" &> /dev/null; then
    missing+=( "$x" )
  fi
done
if ! { command -v python || command -v python3; } &> /dev/null; then
  missing+=( "python or python3" )
fi
if [ "${#missing[@]}" -gt 0 ]; then
  echo 'ERROR: Missing required utilities.' >&2
  {
    for x in "${missing[@]}"; do
      echo "  - $x"
    done
  } | LC_ALL=C sort | cat >&2
cat <<'EOF'
REQUIREMENTS
  BSD or GNU coreutils
  BSD or GNU awk
  jq - https://jqlang.org/
  yq - https://github.com/mikefarah/yq
EOF
  exit 1
fi
unset missing

filter() {
  {
# The extended regex for sed is so large that I am splitting it across multiple
# lines for readability with this filter command.
cat <<'EOF'
# substitute from line beginning
s/^

# ip
([^ ]+)

# timestamp
[^\[]+\[([^]]+)\] +

# method
"([^ ]+) +

# path
(\/[^/]+\/([^/]+)[^ ]+) [^"]+" +

# http code
([0-9]+) +

# unknown
[-0-9]+ +

# download and upload bytes
([0-9]+) ([0-9]+) +

# useragent
"([^"]*)"

# everything else
.*

# replacement text after /
/
  - ip: \1\n
    timestamp: '\2'\n
    http_method: \3\n
    path: '\4'\n
    repository: '\5'\n
    http_code: \6\n
    download_bytes: \7\n
    upload_bytes: \8\n
    useragent: >-\n
      \9\n
/
EOF
  } | grep -v '^#' | tr -d '\n'
}

replace() {
  {
    #if type -P gsed &> /dev/null; then
    #  gsed -r "$@"
    #elif [ "$(uname)" = Darwin ]; then
    if [ "$(uname)" = Darwin ]; then
      sed -E -e 's/\\"/\x01/g' -e "$@" -e 's/\x01/"/g'
    else
      sed -r "$@"
    fi
  } | grep -v '^$'
}

summarize_by() {
  local summarize="${1:-bytes}"
  local group_by_field="${2:-repository}"
  local threshold="${3:-0}"
  local limit="${4:-0}"

  case "$summarize" in
    bytes)
      yq -o=json .requests | jq --arg field "$group_by_field" --argjson threshold "$threshold" --argjson limit "$limit" '{
        ("download_bytes_by_" + $field): (group_by(.[$field]) | map({(.[0][$field] | tostring): (map(.download_bytes) | add)}) | add | to_entries | sort_by(.value) | reverse | map(select(.value >= $threshold)) | if $limit > 0 then .[:$limit] else . end | from_entries),
        ("upload_bytes_by_" + $field): (group_by(.[$field]) | map({(.[0][$field] | tostring): (map(.upload_bytes) | add)}) | add | to_entries | sort_by(.value) | reverse | map(select(.value >= $threshold)) | if $limit > 0 then .[:$limit] else . end | from_entries)
      }' | {
        if [ "$group_by_field" = path ]; then
          cat
        else
          yq -P
        fi
      }
      ;;
    requests)
      yq -o=json .requests | jq --arg field "$group_by_field" --argjson threshold "$threshold" --argjson limit "$limit" '{
        ("requests_by_" + $field): (group_by(.[$field]) | map({(.[0][$field] | tostring): length}) | add | to_entries | sort_by(.value) | reverse | map(select(.value >= $threshold)) | if $limit > 0 then .[:$limit] else . end | from_entries)
      }' | {
        if [ "$group_by_field" = path ]; then
          cat
        else
          yq -P
        fi
      }
      ;;
    *)
      echo "Unknown summarize type: $summarize" >&2
      echo "Supported types: bytes, requests" >&2
      return 1
      ;;
  esac
}

yaml_complex_keys_to_human_readable() {
  awk '
    /^[[:space:]]*\? / {
        sub(/\? /, "\"")
        key = $0
        getline
        sub(/^[[:space:]]*: /, "", $0)
        print key "\": " $0
        next
    }
    { print }
    '
}

human_readable_bytes() {
  if [ "$bytes_only" = true ] || [ ! "$count_by" = bytes ]; then
    cat
    return
  fi
  yq -P | yaml_complex_keys_to_human_readable | \
  awk '{
    if (NF ~ /^[0-9]+$/) {
      bytes = $NF
      if (bytes >= 1000000000000) {
        hr = sprintf("%.1fTB", bytes / 1000000000000)
      } else if (bytes >= 1000000000) {
        hr = sprintf("%.1fGB", bytes / 1000000000)
      } else if (bytes >= 1000000) {
        hr = sprintf("%.1fMB", bytes / 1000000)
      } else if (bytes >= 1000) {
        hr = sprintf("%.1fKB", bytes / 1000)
      } else {
        hr = bytes "B"
      }
      if (hr ~ /\.0[KMGTP]B$/) sub(/\.0/, "", hr)
      sub(/[0-9]+$/, hr)
    }
    print
  }'
}

requests_to_yaml() {
  echo 'requests:'
  grep -F '/repository/' | replace "$(filter)" | clf_to_unix
}

help_summarize() {
  echo 'Summarize by:' | yq -P
  echo '  [ '"$(yq '.requests[0] | keys | map(select(test("_bytes$") | not)) | join(", ")' "$TMP_DIR"/requests.yaml)"' ]'
}

default_summary() {
  help_summarize
  echo "See help for more options: \"${0##*/} --help\"" | yq -P
  {
    summarize_by "$count_by" repository 0 5 < "$TMP_DIR"/requests.yaml | \
      human_readable_bytes
    echo 'request_example:'
    yq '.requests[0] | [.]' "$TMP_DIR"/requests.yaml
  } | yq -P
}

filter_requests_by() {
    local method="${1:-literal}"
    local field="${2:-}"
    local value="${3:-}"
    local invert_opt=""

    if [ "${invert_filter:-}" = true ]; then
      invert_opt=" | not"
    fi

    case "$method" in
      literal)
        echo 'requests:'
        VALUE="$value" yq ".requests[] | select((.$field == env(VALUE))${invert_opt:-}) | [.]" | \
          sed 's/^/  /'
        ;;
      regex)
        echo 'requests:'
        VALUE="$value" yq ".requests[] | select(.$field | test(env(VALUE))${invert_opt:-}) | [.]" | \
          sed 's/^/  /'
        ;;
      timestamp)
        echo 'requests:'
        local conditions=()
        if [ -n "${timestamp_after:-}" ]; then
          conditions+=(".unix_time >= (env(TIMESTAMP_AFTER) | tonumber)")
        fi
        if [ -n "${timestamp_before:-}" ]; then
          conditions+=(".unix_time <= (env(TIMESTAMP_BEFORE) | tonumber)")
        fi
        local filter
        # join filters separated by " and "; IFS only supports one character.
        filter=$(IFS='%'; echo "${conditions[*]}" | sed 's/%/ and /g')

        TIMESTAMP_AFTER="${timestamp_after:-}" TIMESTAMP_BEFORE="${timestamp_before:-}" \
          yq ".requests[] | select((${filter})${invert_opt:-}) | [.]" | \
          sed 's/^/  /'
        ;;
      *)
        echo "Unknown filter method: $method" >&2
        echo "Supported methods: literal, regex, timestamp" >&2
        return 1
        ;;
    esac
}

clf_to_timestamp_python_script() {
cat << 'PYTHON_EOF'
from __future__ import print_function
import sys
import re
import calendar
from datetime import datetime, timedelta

# Common CLF timestamp pattern components
CLF_DATETIME = r'\d{1,2}/[A-Za-z]{3}/\d{4}:\d{2}:\d{2}:\d{2}'
CLF_TIMEZONE = r'([+-])(\d{2})(\d{2})'

# Pattern for Unix timestamp (integer)
unix_pattern = re.compile(r'^[0-9]+$')

# Pattern for YAML format: timestamp: 'DD/Mon/YYYY:HH:MM:SS +ZZZZ'
yaml_pattern = re.compile(
    r"^(\s*)(timestamp:\s*)['\"]?\s?(" + CLF_DATETIME + r")\s+" + CLF_TIMEZONE + r"['\"]?(.*)$"
)

# Pattern for raw CLF timestamp: DD/Mon/YYYY:HH:MM:SS +ZZZZ
raw_clf_pattern = re.compile(
    r"^\s*(" + CLF_DATETIME + r")\s+" + CLF_TIMEZONE + r"\s*$"
)

def clf_to_unix_ts(ts_datetime, tz_sign, tz_hours, tz_mins):
    """Convert CLF timestamp components to Unix timestamp."""
    dt = datetime.strptime(ts_datetime, '%d/%b/%Y:%H:%M:%S')
    offset_seconds = (tz_hours * 3600) + (tz_mins * 60)
    if tz_sign == '+':
        dt = dt - timedelta(seconds=offset_seconds)
    else:
        dt = dt + timedelta(seconds=offset_seconds)
    return calendar.timegm(dt.timetuple())

for line in sys.stdin:
    line = line.rstrip('\n\r')

    # Check for Unix timestamp first (exit early)
    if unix_pattern.match(line):
        print(line)
        continue

    # Check for YAML format: timestamp: '...'
    yaml_match = yaml_pattern.match(line)
    if yaml_match:
        print(line)
        indent = yaml_match.group(1)
        ts_datetime = yaml_match.group(3)
        tz_sign = yaml_match.group(4)
        tz_hours = int(yaml_match.group(5))
        tz_mins = int(yaml_match.group(6))
        try:
            unix_ts = clf_to_unix_ts(ts_datetime, tz_sign, tz_hours, tz_mins)
            print('{0}unix_time: {1}'.format(indent, unix_ts))
        except ValueError:
            pass
        continue

    # Check for raw CLF timestamp
    raw_match = raw_clf_pattern.match(line)
    if raw_match:
        ts_datetime = raw_match.group(1)
        tz_sign = raw_match.group(2)
        tz_hours = int(raw_match.group(3))
        tz_mins = int(raw_match.group(4))
        try:
            unix_ts = clf_to_unix_ts(ts_datetime, tz_sign, tz_hours, tz_mins)
            print(unix_ts)
        except ValueError:
            print(line)
        continue

    # Default: passthrough
    print(line)
PYTHON_EOF
}

clf_to_unix() {
  # Read Common Log Format (CLF) timestamp and append `unix_time:` timestamp.
  local python_cmd
  if command -v python3 &>/dev/null; then
    python_cmd=python3
  else
    python_cmd=python
  fi
  "$python_cmd" <(clf_to_timestamp_python_script)
}

color_example() {
  if [ -z "${NO_COLOR:-}" ]; then
    echo $'\e[95m'"$*"$'\e[0m'
  else
    echo "$*"
  fi
}

color_section() {
  if [ -z "${NO_COLOR:-}" ]; then
    echo $'\e[34m'"$*"$'\e[0m'
  else
    echo "$*"
  fi
}

color_script() {
  if [ -z "${NO_COLOR:-}" ]; then
    echo $'\e[32m'"$*"$'\e[0m'
  else
    echo "$*"
  fi
}

helptext() {
cat <<EOF
$(color_section "SYNOPSIS:")
  $(color_script "${0##*/}") $(color_example "[-f FIELD=VALUE] [-i] [-r|--requests] [-y] [--] [FILE...]")
  $(color_script "${0##*/}") $(color_example "[-g FIELD=VALUE] [-i] [-r|--requests] [-y] [--] [FILE...]")
  $(color_script "${0##*/}") $(color_example "[-b] [-c] [-l LIMIT] [-s FIELD] [-t COUNT] [-y] [--] [FILE...]")
  $(color_script "${0##*/}") $(color_example "[-h|--help]")

$(color_section "DESCRIPTION:")
  Processes a Sonatype Nexus request log and attempts to make sense of a large
  volume of requests.  Intended to help track down sources of request load
  spikes (amount and data).

  Converts a Sonatype Nexus request log into YAML.

$(color_section "INPUT OPTIONS:")
  Changes input processing behavior.

  $(color_example "-y, --yaml")
    Force assuming YAML input.  Skips request log preprocessing to YAML.  This
    option may only be required if you're assembling your own YAML and the
    binary header is not "requests:".

  $(color_example "--")
    Stop processing options and treat all remaining arguments as files.

$(color_section "REQUEST OUTPUT OPTIONS:")
  Dumps request log as YAML output.  Running this script reading a request log
  already converted to YAML cuts run time by roughly half.  These options
  always result in a YAML dump of requests.

  $(color_example "-a TIMESTAMP, --after TIMESTAMP")
    Filter requests occurring after (inclusive) the $(color_example "TIMESTAMP").  $(color_example "TIMESTAMP") can
    be either a Common Log Format (CLF) $(color_example "timestamp") or a $(color_example "unix_time") timestamp.

  $(color_example "-b TIMESTAMP, --before TIMESTAMP")
    Filter requests occurring before (inclusive) the $(color_example "TIMESTAMP").  $(color_example "TIMESTAMP") can
    be either a Common Log Format (CLF) $(color_example "timestamp") or a $(color_example "unix_time") timestamp.

  $(color_example "-f FIELD=VALUE, --filter-value FIELD=VALUE")
    Filter requests by a literal value in a particular field and exit.

  $(color_example "-g FIELD=VALUE, --filter-regex FIELD=VALUE")
    Filter requests by partial or regex in a particular field and exit.

  $(color_example "-i, --invert-filter")
    Invert matching when using $(color_example "--filter-regex") or $(color_example "--filter-value").

  $(color_example "-r, --requests")
    Print raw YAML of requests and exit.  Other options may filter output.

$(color_section "SUMMARIZING DATA OPTIONS:")
  $(color_example "-s FIELD, --sumarize-by FIELD")
    Print a summary grouped by a particular request $(color_example "FIELD").
    Default: $(color_example "repository")

  $(color_example "-c, --count-requests")
    Count number of requests instead of bytes of requested transfer.

  $(color_example "-t COUNT, --threshold COUNT")
    A summarized item must be above a threshold of $(color_example "COUNT") in order to be printed
    (e.g. bytes or request count).  $(color_example "--limit-summary LIMIT") can be disabled for
    this option to be most effective.
    Default: $(color_example "0") (Include all)

  $(color_example "-l LIMIT, --limit-summary LIMIT")
    Summarized items will print up to $(color_example "LIMIT") entries.
    Disable with: $(color_example "--limit-summary 0")
    Default: $(color_example "10") (or 10 entries)

  $(color_example "-n, --bytes-only")
    By default, this script will convert bytes to human readable bytes like KB,
    MB, GB, or TB.  If this options is passed only the raw bytes value is
    output in a summary of upload/download bytes.

$(color_section "EXAMPLES:")
  Usage examples which help you make the most of this utility.  It is designed
  to process input from Nexus request logs or its own YAML.

  Convert a large request log to YAML for analyzing further.

    $(color_script "${0##*/}") $(color_example "-r path/to/requests.log > /tmp/requests.yaml")
    # summarize the output (all examples work with requests.yaml)
    $(color_script "${0##*/}") $(color_example "/tmp/requests.yaml")

  Summarize a particular day or hour in a request log.

    $(color_script "grep") $(color_example "'some timestamp' path/to/requests.log |") \\
      $(color_script "${0##*/}")

  Get a spread of HTTP methods used by request count.

    $(color_script "${0##*/}") $(color_example "-s http_method -c path/to/requests.log")

  Show all IP addresses which transferred more than 1GB without limit.

    $(color_script "${0##*/}") $(color_example "-s ip -t 1000000000 -l 0 path/to/requests.log")

  Print largest data transfers requested within same second period.

    $(color_script "${0##*/}") $(color_example "-s timestamp path/to/requests.log")

  Find all IP addresses which downloaded or uploaded a particular file.  You
  must first dump all requests filtered by the file path followed by
  summarizing requests by ip field.

    $(color_script "${0##*/}") $(color_example "-r -f path='/repository/example/file' path/to/requests.log | \\")
      $(color_script "${0##*/}") $(color_example "-y -s ip -l 0")

  For a specific repository, get the top 10 bytes transferred by file within
  the given repository.

    $(color_script "${0##*/}") $(color_example "-r -f repository=example path/to/requests.log | \\")
      $(color_script "${0##*/}") $(color_example "-y -s path")

  For a specific repository, get the top 20 amount of requests by path.  Use yq
  to pretty print the result.

    $(color_script "${0##*/}") $(color_example "-r -f repository=example path/to/requests.log | \\")
      $(color_script "${0##*/}") $(color_example "-y -c -s path -l 20 | \\")
      $(color_script "yq") $(color_example "-P")

$(color_section "AUTHOR:")
  Created by Sam Gleske (https://github.com/samrocketman)
  MIT Licensed
EOF
}

#
# MAIN
#
files=( )
raw_requests=false
summary_field=repository
count_by=bytes
threshold_min=0
max_limit=10
# only some options should overwrite the default summary
options_processed=false
bytes_only=false
filter_value=""
yaml_input=false
filter_method=literal
invert_filter=false
timestamp_after=""
timestamp_before=""
while [ "$#" -gt 0 ]; do
  case "${1:-}" in
    -a|--after)
      options_processed=true
      raw_requests=true
      timestamp_after="$(clf_to_unix <<< "${2:-}")"
      if ! { grep '^[0-9]\+$' <<< "${timestamp_after:-}" &> /dev/null; }; then
        echo 'ERROR: --after timestamp must be CLF timestamp or unix timestamp.' >&2
        exit 1
      fi
      shift
      ;;
    -b|--before)
      options_processed=true
      raw_requests=true
      timestamp_before="$(clf_to_unix <<< "${2}")"
      if ! { grep '^[0-9]\+$' <<< "${timestamp_before:-}" &> /dev/null; }; then
        echo 'ERROR: --before timestamp must be CLF timestamp or unix timestamp.' >&2
        exit 1
      fi
      shift
      ;;
    -c|--count-requests)
      count_by=requests
      ;;
    -f|--filter-value)
      options_processed=true
      summary_field="${2%%=*}"
      filter_value="${2#*=}"
      raw_requests=true
      filter_method=literal
      shift
      ;;
    -g|--filter-regex)
      options_processed=true
      summary_field="${2%%=*}"
      filter_value="${2#*=}"
      raw_requests=true
      filter_method=regex
      shift
      ;;
    -i|--invert-filter)
      invert_filter=true
      ;;
    -h|--help)
      helptext | {
        if type -P less &> /dev/null; then
          less -R
        else
          cat
        fi
      }
      exit 1
      ;;
    -l|--limit-summary)
      options_processed=true
      max_limit="$2"
      shift
      ;;
    -n|--bytes-only)
      bytes_only=true
      ;;
    -r|--requests)
      options_processed=true
      raw_requests=true
      ;;
    -s|--summarize-by)
      options_processed=true
      summary_field="$2"
      shift
      ;;
    -t|--threshold)
      options_processed=true
      threshold_min="$2"
      shift
      ;;
    -y|--yaml)
      yaml_input=true
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "ERROR: unknown option '$1'" >&2
      echo 'See also --help' >&2
      exit 1
      ;;
    *)
      if [ ! -f "$1" ]; then
        echo 'ERROR: file "'"$1"'" does not exist or is not a file.' >&2
        echo 'See also --help' >&2
        exit
      fi
      files+=( "$1" )
      ;;
  esac
  shift
done

if {
  [ -n "${timestamp_after:-}" ] && \
    [ -n "${timestamp_before:-}" ] && \
    [ "${timestamp_after}" -gt "${timestamp_before}" ]
}; then
  echo 'ERROR: --after timestamp must be earlier than --before timestamp.' >&2
  exit 1
fi

# process the rest of arguments as files
while [ "$#" -gt 0 ]; do
  if [ ! -f "$1" ]; then
    echo 'ERROR: file "'"$1"'" does not exist or is not a file.' >&2
    echo 'See also --help' >&2
    exit
  fi
  files+=( "$1" )
  shift
done

# convert to YAML
{
  if [ "${#files[@]}" -eq 0 ]; then
    cat
  else
    cat "${files[@]}"
  fi
} | {
  # auto-detect --yaml in first 9 bytes i.e. 9 characters of 'requests:'
  dd of="${TMP_DIR}"/header count=1 bs=9 status=none
  if [ "$(< "${TMP_DIR}"/header)" = 'requests:' ]; then
    yaml_input=true
  fi
  {
    # write the 9-byte header to stdout and resume dump of all data with cat
    dd if="${TMP_DIR}"/header count=1 bs=9 status=none
    cat
  } | {
    if [ "$yaml_input" = true ]; then
      cat
    else
      # shellcheck disable=SC2016
      requests_to_yaml | \
        yq 'with(.requests[]; .useragent_id = (.useragent | @base64 | sub("=", "") | sub("^(.{0,10}).*$"; "${1}")))'
    fi
  }
} > "$TMP_DIR"/requests.yaml

if [ "$options_processed" = false ]; then
  default_summary
  exit
fi

if [ "$raw_requests" = true ]; then
  {
    if [ -n "${filter_value:-}" ]; then
      filter_requests_by "$filter_method" "$summary_field" "$filter_value" < "$TMP_DIR"/requests.yaml
    else
      cat "$TMP_DIR"/requests.yaml
    fi
  } | {
    if {
      [ -n "${timestamp_after:-}" ] || \
      [ -n "${timestamp_before:-}" ]
    }; then
      filter_requests_by timestamp
    else
      cat
    fi
  }
  exit
fi

summarize_by "$count_by" "$summary_field" "$threshold_min" "$max_limit" \
  < "$TMP_DIR"/requests.yaml | \
  human_readable_bytes | {
  if [ "$summary_field" = path ]; then
    cat
  else
    yq -P
  fi
}
