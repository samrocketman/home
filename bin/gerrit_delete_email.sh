#!/bin/bash
#Created by Sam Gleske

#DESCRIPTION:
#  Delete an email from Gerrit.
#  Gerrit no longer requires a restart.
#  Environment variables that can be overridden:
#    - GERRIT_URL
#    - GERRIT_USER
#    - GERRIT_HOST

#USAGE:
#  GERRIT_HOST="https://gerrit.example.com" ./gerrit_delete_email.sh email@example.com

if [ -z "$1" ]; then
  echo 'Missing email as first argument.'
  exit 1
fi

if [ -z "${GERRIT_URL}" ]; then
  echo "GERRIT_URL env var is not set"
  exit 1
fi
GERRIT_URL="${GERRIT_URL%/}"
GERRIT_USER="${GERRIT_USER:-$USER}"
GERRIT_HOST="${GERRIT_HOST:-${GERRIT_URL##*/}}"

email="$1"

function json_id() {
  python -c '
import sys,json
x=sys.stdin.read().split("\n")
try:
  x.pop(0)
  print json.loads("\n".join(x))["username"]
except:
  print ""
'
}

uid="$(curl -sL "${GERRIT_URL}/accounts/${email}" | json_id)"

if [ -z "$uid" ]; then
  echo "Error: No UID found for ${email}.  Try the following."
  echo "curl -sL ${GERRIT_URL}/accounts/${email}"
  exit 1
fi

set -x
ssh ${GERRIT_USER}@${GERRIT_HOST} gerrit set-account --delete-email ${email} ${uid}
