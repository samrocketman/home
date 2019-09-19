#!/bin/bash
# Created by Sam Gleske
# DESCRIPTION:
#   This script will monitor a GitHub pull request and wait until it is ready
#   to merge.  The means merging will be unblocked after all GitHub checks
#   passed and any peer reviews submitted if they are required to merge.

set -euo pipefail

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo 'ERROR: Missing GITHUB_TOKEN credential with repo scope.' >&2
  say_job_done.sh 'Error, missing auth token.'
  exit 1
fi

if ! grep '^https://github.com/[^/]\+/[^/]\+/pull/[0-9]\+$' <<< "$1" &> /dev/null; then
  echo 'ERROR: Received invalid pull request URL.' >&2
  echo "$1" >&2
  say_job_done.sh 'Error, bad pool request U-R-L.'
  exit 1
fi

for x in curl jq; do
  if ! type -P "$x" &> /dev/null; then
    echo "ERROR: ${x} is missing." >&2
    exit 1
  fi
done

project="${1#https://github.com/}"
project="${project%/pull/*}"
pr_number="${1##*/}"
export project pr_number

function getMergeableState() {
    curl -fsH "Authorization: token $GITHUB_TOKEN" \
      https://api.github.com/repos/"${project}/pulls/${pr_number}" |
      jq -r '.mergeable_state'
}

waited=false

until [ "$(getMergeableState)" = clean -o "$(getMergeableState)" = unknown ]; do
  echo -n '.'
  sleep 3
  waited=true
done
[ "${waited}" = false ] || echo
if [ "$(getMergeableState)" = unknown ]; then
  say_job_done.sh "Pool request ${pr_number}, is unknown but possibly merged."
else
  say_job_done.sh "Pool request ${pr_number}, is ready to merge."
fi
