#!/bin/bash
# Created by Sam Gleske (GitHub @samrocketman)
# Downloads the latest docker-compose binary and verifies the checksum.  This
# script is idempotent.  It will install docker-compose only if it is not the
# latest.

function latest_tag() {
  curl -sfI "${RELEASES}"/latest |
  tr '\r' '\n' |
  awk '$1 == "Location:" { gsub(/^.*\//, "", $2);print $2 }'
}; declare -rf latest_tag

# get the checksum for the downloaded binary
function checksum() {
  curl -sfL "${RELEASES}/download/${TAG}/${CHECKSUM_FILE}" |
  awk "\$0 ~ /${BINARY}\$/ { print \$1 }"
}; declare -rf checksum

function sha256sum() (
  if type -P sha256sum > /dev/null; then
    command sha256sum "${@}"
  elif type -P shasum > /dev/null; then
    command shasum -a 256 "${@}"
  else
    echo 'ERROR: could not find a sha256sum program.' >&2
    exit 1
  fi
); declare -rf sha256sum

set -auxeEo pipefail

DESTINATION="${DESTINATION:-${HOME}/usr/bin/docker-compose}"
RELEASES="https://github.com/docker/compose/releases"
TAG="$( latest_tag )"
BINARY="docker-compose-$(uname -s)-$(uname -m)"
CHECKSUM_FILE="${BINARY}.sha256"
if [ ! -x "${DESTINATION}" ] ||
    ! sha256sum -c - <<< "$(checksum)  ${DESTINATION}"; then
  curl -fLo "${DESTINATION}" "${RELEASES}/download/${TAG}/${BINARY}"
  sha256sum -c - <<< "$(checksum)  ${DESTINATION}"
  chmod 755 "${DESTINATION}"
fi
