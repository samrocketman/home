#!/bin/bash

set -e
TMP_DIR="$(mktemp -d)"
trap '[ ! -d "${TMP_DIR}" ] || rm -rf "${TMP_DIR}"' EXIT

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo 'ERROR: Missing GITHUB_TOKEN credential.' >&2
  say_job_done.sh 'Error, missing auth token.'
  exit 1
fi

if ! grep '[a-f0-9]\{40\}' <<< "$1" > /dev/null; then
  echo 'ERROR: must provide a GH commit URL to query.' >&2
  echo '    Example:'
  echo "        ${0##*/} https://github.com/endless-sky/endless-sky/commit/f7206b3bee9ded973238f2dfb4e348fcb63397f2" >&2
  echo "        ${0##*/} https://github.com/endless-sky/endless-sky/commit/f7206b3bee9ded973238f2dfb4e348fcb63397f2 context1 context2 etc" >&2
  exit 1
fi

function isComplete() {
  [ "${1:-}" = success ] || [ "${1:-}" = error ] || [ "${1:-}" = failure ]
}

function isError() {
  [ "${1:-}" = error ] || [ "${1:-}" = failure ]
}

function getStatusForContext() {
  yq '.statuses[] | select(.context == "'"$1"'") | .state // "unknown"' \
    "${TMP_DIR}"/commit-status
}

function getCommitStatus() {
  curl -sSfLH "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/repos/"${OWNER_REPO}"/commits/"${COMMIT_REF}"/status \
    > "${TMP_DIR}"/commit-status
  if [ x"${CONTEXTS:-}" = x ]; then
    BUILD_RESULT="$(jq -r '.state' "${TMP_DIR}"/commit-status)"
  else
    local tmp_result
    local is_pending=0
    for x in "${CONTEXTS[@]}"; do
      tmp_result="$(getStatusForContext "$x")"
      if isError "${tmp_result}"; then
        break
      fi
      if ! isComplete "${tmp_result}"; then
        is_pending="$(( is_pending + 1 ))"
      fi
    done
    if isError "${tmp_result}"; then
      BUILD_RESULT="${tmp_result}"
    elif [ "${is_pending}" -gt 0 ]; then
      BUILD_RESULT=pending
    else
      BUILD_RESULT=success
    fi
  fi
  echo "${BUILD_RESULT}" > "${TMP_DIR}"/result
  if isComplete "${BUILD_RESULT:-}"; then
    echo completed
  else
    echo pending
  fi
}

OWNER_REPO="$(cut -d/ -f 4,5 <<< "$1")"
COMMIT_REF="$(grep -o '[a-f0-9]\{40\}' <<< "$1")"
shift
CONTEXTS=()
if [ "$#" -gt 0 ]; then
  for x in "$@"; do
    CONTEXTS+=( "$x" )
  done
fi

waited=false
until [ "$(getCommitStatus)" = completed ]; do
  echo -n '.'
  sleep 5
  waited=true
done
[ "${waited}" = false ] || echo
project="$(tr '-' ' ' <<< "${OWNER_REPO#*/}")"
say_job_done.sh "${project} completed with $(<"${TMP_DIR}"/result)."
