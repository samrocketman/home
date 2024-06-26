#!/bin/bash

set -euo pipefail

create_tmp() {
  export exec_tmp
  exec_tmp="$(mktemp -d)"
  touch "$exec_tmp"/file
  chmod 755 "$exec_tmp"/file
  if [ ! -x "$exec_tmp"/file ]; then
    rm -r "$exec_tmp"
  else
    return 0
  fi
  mkdir -p ~/usr/tmp
  exec_tmp=~/usr/tmp
  touch "$exec_tmp"/file
  chmod 755 "$exec_tmp"/file
  if [ ! -x "$exec_tmp"/file ]; then
    rm -r "$exec_tmp"
    echo 'No suitable exec_tmp could be created.' >&2
    return 1
  fi
  rm "$exec_tmp"/file
}

checksum() (
  if type -P shasum &> /dev/null; then
    shasum -a 256 -c -
  else
    sha256sum -c -
  fi
)

install_download_sh() (
  yaml_file=~/git/home/misc/download-utilities.yml
  vers="$(awk '$1 == "download-utilities.sh:" {print $2; exit}' "${yaml_file}" | xargs)"
  checksum_hash="$(awk 'BEGIN {skip=1} $0 ~ /^checksums:/ {skip=0}; skip {next}; $1 == "download-utilities.sh:" {print $2; exit}' "${yaml_file}" | xargs)"

  curl -sSfL \
    https://github.com/samrocketman/yml-install-files/releases/download/v"${vers}"/universal.tgz | \
  tar -xzC "$exec_tmp"/ --no-same-owner download-utilities.sh
  echo "${checksum_hash}  ${exec_tmp}/download-utilities.sh" | \
  checksum || (retval=$?; sha256sum "${exec_tmp}/download-utilities.sh"; return "${retval}"; )
  chmod 755 "${exec_tmp}/download-utilities.sh"
)

cleanup_on() {
  if [ -d "${exec_tmp:-}" ]; then
    rm -rf "${exec_tmp}"
  fi
}

trap cleanup_on EXIT
create_tmp
install_download_sh
export PATH="$exec_tmp:$PATH"

cd ~
# self-bootstrap of yq required since I am installing yq via yaml
export force_yq=1
download-utilities.sh ~/git/home/misc/download-utilities.yml
