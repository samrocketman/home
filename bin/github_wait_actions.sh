#!/bin/bash

set -

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo 'ERROR: Missing GITHUB_TOKEN credential.' >&2
  say_job_done.sh 'Error, missing auth token.'
  exit 1
fi

if ! grep -F "actions/runs" <<< "$1"; then
  echo 'ERROR: must provide a GH action to query.' >&2
  echo '    Example:'
  echo "        ${0##*/} https://github.com/samrocketman/endless-sky/actions/runs/2391215893" >&2
  exit 1
fi

function getWorkflowStatus() {
curl -sSfLH "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/"${OWNER_REPO}"/actions/runs/"${WORKFLOW_ID}" | \
  jq -r '.status'
}

OWNER_REPO="$(sed 's#^https://github.com/\([^/]\+/[^/]\+\)/.*#\1#' <<< "$1")"
WORKFLOW_ID="${1##*/}"

waited=false
until [ "$(getWorkflowStatus)" = completed ]; do
  echo -n '.'
  sleep 5
  waited=true
done
[ "${waited}" = false ] || echo
project="$(tr '-' ' ' <<< "${OWNER_REPO#*/}")"
say_job_done.sh "${project} Git Hub Action has completed."
