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
set -euo pipefail
export TMP_DIR
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

missing=( )
for x in awk cat grep jq sed yq; do
  if ! type -P "$x" &> /dev/null; then
    missing+=( "$x" )
  fi
done
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
([0-9]+)

# download and upload bytes
[^0-9]+([0-9]+) ([0-9]+)

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
      sed -E "$@"
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
  grep -F '/repository/' | replace "$(filter)"
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
    local field="$1"
    local value="$2"
    echo 'requests:'
    VALUE="$value" yq ".requests[] | select(.$field == env(VALUE)) | [.]" | \
      sed 's/^/  /'
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
  $(color_script "${0##*/}") $(color_example "[-r|--requests] [--] [FILE...]")
  $(color_script "${0##*/}") $(color_example "[-l LIMIT] [-s FIELD] [--] [FILE...]")

$(color_section "DESCRIPTION:")
  Processes a Sonatype Nexus request log and attempts to make sense of a large
  volume of requests.  Intended to help track down sources of request load
  spikes (amount and data).

  Converts a Sonatype Nexus request log into YAML.

$(color_section "INPUT OPTIONS:")
  $(color_example "-y, --yaml")
    Assume YAML input has already been processed by this script.  Useful for
    getting summaries by filtered fields.

  $(color_example "--")
    Stop processing options and treat all remaining arguments as files.

$(color_section "REQUEST OPTIONS:")
  $(color_example "-r, --requests")
    Print raw YAML of requests and exit.  Ignores all other options except for
    $(color_example "--filter-by").

  $(color_example "-f FIELD=VALUE, --filter-by FIELD=VALUE")
    Filter requests by a value in a particular field.  Only applies to
    $(color_example "--requests").

$(color_section "OUTPUT OPTIONS:")
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

  $(color_example "-b, --bytes-only")
    By default, this script will convert bytes to human readable bytes like KB,
    MB, GB, or TB.  If this options is passed only the raw bytes value is
    output in a summary of upload/download bytes.

$(color_section "EXAMPLES:")
  Summarize a particular day or hour in a request log.

    $(color_example "grep 'some timestamp' path/to/requests.log |") $(color_script "${0##*/}")

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
      $(color_example "yq -P")

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
while [ "$#" -gt 0 ]; do
  case "${1:-}" in
    -b|--bytes-only)
      bytes_only=true
      ;;
    -c|--count-requests)
      count_by=requests
      ;;
    -y|--yaml)
      yaml_input=true
      ;;
    -r|--requests)
      options_processed=true
      raw_requests=true
      ;;
    -f|--filter-by)
      summary_field="${2%%=*}"
      filter_value="${2#*=}"
      shift
      ;;
    -t|--threshold)
      options_processed=true
      threshold_min="$2"
      shift
      ;;
    -l|--limit-summary)
      options_processed=true
      max_limit="$2"
      shift
      ;;
    -s|--summarize-by)
      options_processed=true
      summary_field="$2"
      shift
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
  if [ "$yaml_input" = true ]; then
    cat
  else
    requests_to_yaml
  fi
} > "$TMP_DIR"/requests.yaml

if [ "$options_processed" = false ]; then
  default_summary
  exit
fi

if [ "$raw_requests" = true ]; then
  if [ -n "${filter_value:-}" ]; then
    filter_requests_by "$summary_field" "$filter_value" < "$TMP_DIR"/requests.yaml
  else
    cat "$TMP_DIR"/requests.yaml
  fi
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
