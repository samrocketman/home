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
  vers=2.12
  checksum_hash=da73e2cdc16e02b2c30ab63260ca7cab2303a1fa4a58e53eda5e21f2679a3da9
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
download-utilities.sh ~/git/home/misc/download-utilities.yml
