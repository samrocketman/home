#!/bin/bash
# Created by Sam Gleske
# Pop!_OS 22.04 LTS
# Linux 6.12.10-76061203-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)

set -euo pipefail

if [ -z "${default_url:-}" ]; then
  if [ -f "${JENKINS_HEADERS_FILE:-}" ]; then
    jenkins_host="$(yq .headers.Host < "$JENKINS_HEADERS_FILE")"
    default_url="https://${jenkins_host}/job/_jervis_generator"
  fi
fi

jenkins_generate_job="${jenkins_generate_job:-${default_url:-}}"
export jenkins_generate_job

echo_stderr() {
  if [ "$#" -lt 1 ]; then
    cat >&2
  else
    echo "$*" >&2
  fi
}

helptext() {
echo_stderr <<EOF
SYNOPSIS
  ${0##*/} URL [org/repo ...]
  ${0##*/} [URL]
  ${0##*/} -h|--help

DESCRIPTION
  Can either read from stdin or as arguments.  Takes a list of projects and
  generates Jervis jobs from YAML on a Jervis-configured Jenkins instance.

ARGUMENTS
  URL
    Optional: URL to the jervis generator job.  Otherwise, the URL is
    discovered by reading the environment variable JENKINS_HEADERS_FILE which
    contains Jenkins headers.

  org/repo
    Optional: GitHub org and project from which to generate jobs with Jervis.
    A list of org/repo lines can be passed to stdin, instead, if this option is
    omitted.

EXAMPLE
  ${0##*/} <<< samrocketman/jervis
EOF
}

case "$#" in
  0)
    true
    ;;
  1)
    case "$1" in -h|--help) helptext; exit; esac
    jenkins_generate_job="$1"
    shift
    ;;
esac

if [ -z "${jenkins_generate_job:-}" ]; then
  echo_stderr 'First argument should be the jervis generator job you want to call.'
  echo_stderr 'Example: '"${0##*/} https://jenkins.example.com/job/_jervis_generator"
fi

get_last_N_jobs() {
  jenkins_call.sh "${jenkins_generate_job}"'/api/json?pretty=true' | \
    yq '.builds[] | .url' | \
    head -n "${1:-1}" \
    || [ "$?" -eq 141 ]
}

get_project_name_from_job() {
  jenkins_call.sh "${1}/api/json?pretty=true" | \
    yq -oyaml '.actions[] | select(.parameters[0].value != null) | .parameters[0].value'
}

find_job_for_repo_name() {
  local repo
  local job_parameter
  repo="$1"
  shift
  for job in "$@"; do
    job_parameter="$(get_project_name_from_job "$job")"
    if [ "$job_parameter" = null ]; then
      echo_stderr "ERROR: parameter was null for $job"
      exit 1
    fi
    if [ "$repo" = "$job_parameter" ]; then
      echo "$job"
      break
    fi
  done
}

trigger_build_for() {
  jenkins_call.sh -m POST 'https://jenkins.303net.net/job/_jervis_generator/buildWithParameters?delay=0sec&project='"$1"
}

generate_and_wait_for() {
  local jenkins_jobs
  local found_job
  local before_found
  local retry_counter=9
  local repo
  repo="$1"
  echo_stderr "Generating job for ${1}"
  # make sure it wasn't generated recently by another means
  jenkins_jobs=( $(get_last_N_jobs 20) )
  before_found="$(find_job_for_repo_name "${repo}" "${jenkins_jobs[@]}")"

  trigger_build_for "${repo}"

  # wait for build to show up
  until {
    jenkins_jobs=( $(get_last_N_jobs 20) )
    found_job="$(find_job_for_repo_name "${repo}" "${jenkins_jobs[@]}")"
    [ ! "${found_job:-}" = "${before_found:-}" ]
  }; do
    retry_counter="$(( ( retry_counter + 1) % 10 ))"
    if [ "$retry_counter" -eq 0 ]; then
      echo_stderr 'Waiting for job to show up.'
    fi
    sleep 1
  done
  SILENT=1 jenkins_wait_job.sh "$found_job"
}

if [ "$#" -lt 1 ]; then
  echo_stderr "Reading from stdin."
  while read line; do
    generate_and_wait_for "$line"
  done
else
  echo_stderr "Processing repositories as arguments."
  for arg in "$@"; do
    generate_and_wait_for "$line"
  done
fi
