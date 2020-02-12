#!/bin/bash
# Mon Feb  3 17:29:07 EST 2020
# Ubuntu 18.04.3 LTS
# Linux 5.3.0-28-generic x86_64
# GNU bash, version 4.4.20(1)-release (x86_64-pc-linux-gnu)
set -exo pipefail

function getLatest() {
  curl https://releases.hashicorp.com/${1}/ | \
  grep -o "${1}_[^<]*" | \
  grep -v '_.*[-+]' | \
  head -n1 | \
  cut -d_ -f2
}

function hashiDownload() {
  local DEST_DIR="${3:-${TMP_DIR:-/tmp}}"
  local kernel="$(uname -s | tr 'A-Z' 'a-z')"
  local arch
  local SHASUM
  if type -P sha256sum; then
    SHASUM=( sha256sum -c )
  elif type -P shasum; then
    SHASUM=( shasum -a 256 -c )
  else
    echo 'ERROR: could not find a valid sha256sum utility.' >&2
    return 1
  fi
  case "$(uname -m)" in
    x86_64)
      arch=amd64
    ;;
  esac
  local version="${2}"
  if [ "${2}" = latest ]; then
    version="$(getLatest "$1")"
  fi
  local zipfile="${1}_${version}_${kernel}_${arch}.zip"
  if [ -z "${FORCE_DOWNLOAD:-}" ] && type -P "${1}"; then
      echo "${1} already exists so skipping downloading.  ${1} --version is..."
      "${1}" --version
      return
  fi
  local PREFIX_URL="${HASHICORP_MIRROR:-https://releases.hashicorp.com}"
  pushd "${DEST_DIR}"
  curl -fLO "${PREFIX_URL}/${1}/${version}/${zipfile}"
  curl -fL "${PREFIX_URL}/${1}/${version}/${1}_${version}_SHA256SUMS" | grep "${zipfile}" | "${SHASUM[@]}"
  unzip "${zipfile}"
  \rm "${zipfile}"
  popd
}

hashiDownload "${@}"
