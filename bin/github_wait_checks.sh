#!/bin/bash

set -e
TMP_DIR="$(mktemp -d)"
trap '[ ! -d "${TMP_DIR}" ] || rm -rf "${TMP_DIR}"' EXIT

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo 'ERROR: Missing GITHUB_TOKEN credential.' >&2
  say_job_done.sh 'Error, missing auth token.'
  exit 1
fi

if ! grep -F "check_run_id" <<< "$1"; then
  echo 'ERROR: must provide a GH check to query.' >&2
  echo '    Example:'
  echo "        ${0##*/} https://github.com/samrocketman/endless-sky/pull/3/checks?check_run_id=1235" >&2
  exit 1
fi

function getCheckRunStatus() {
  curl -sSfLH "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/repos/"${OWNER_REPO}"/check-runs/"${CHECK_RUN_ID}" \
    > "${TMP_DIR}"/check-run
  jq -r '.status' "${TMP_DIR}"/check-run
}

function getCheckRunName() {
  jq -r '.name' "${TMP_DIR}"/check-run
}
function getCheckRunResult() {
  jq -r '.conclusion' "${TMP_DIR}"/check-run
}

OWNER_REPO="$(cut -d/ -f 4,5 <<< "$1")"
CHECK_RUN_ID="${1##*check_run_id=}"

waited=false
until [ "$(getCheckRunStatus)" = completed ]; do
  echo -n '.'
  sleep 5
  waited=true
done
[ "${waited}" = false ] || echo
project="$(tr '-' ' ' <<< "${OWNER_REPO#*/}")"
say_job_done.sh "${project} Git Hub Check Run $(getCheckRunName) has finished."
sleep .3
say_job_done.sh "with status $(getCheckRunResult)"
