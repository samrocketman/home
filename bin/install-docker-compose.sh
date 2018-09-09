#!/bin/bash
# Created by Sam Gleske (GitHub @samrocketman)
# Downloads the latest docker-compose binary and verifies the checksum.

DESTINATION="${DESTINATION:-${HOME}/usr/bin/docker-compose}"

function latest_tag() {
  curl -sfI https://github.com/docker/compose/releases/latest |
  tr '\r' '\n' |
  awk '$1 == "Location:" { gsub(/^.*\//, "", $2);print $2 }'
}; declare -rf latest_tag

# get the checksum for the downloaded binary
function checksum() {
  curl -sfL "https://github.com/docker/compose/releases/download/${TAG}/${BINARY}.sha256" |
  awk "\$0 ~ /${BINARY}\$/ { print \$1 }"
}; declare -rf checksum

function sha256sum() {
  if type -P sha256sum > /dev/null; then
    command sha256sum "${@}"
  elif type -P shasum > /dev/null; then
    command shasum -a 256 "${@}"
  else
    echo "ERROR: could not find a sha256sum program."
    exit 1
  fi
}; declare -rf sha256sum

set -auxeEo pipefail

if [ ! -x "${DESTINATION}" ]; then
  TAG="$( latest_tag )"
  BINARY="docker-compose-$(uname -s)-$(uname -m)"

  curl -fLo "${DESTINATION}" "https://github.com/docker/compose/releases/download/${TAG}/${BINARY}"
  sha256sum -c - <<< "$(checksum)  ${DESTINATION}"
  chmod 755 "${DESTINATION}"
fi
