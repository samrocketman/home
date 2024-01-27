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

checksum_file() (
  if type -P shasum &> /dev/null; then
    shasum -a 256 -c -
  else
    sha256sum -c -
  fi
)

install_download_sh() (
  curl -sSfL \
    https://github.com/samrocketman/yml-install-files/releases/download/v2.16/universal.tgz | \
  tar -xzC "$exec_tmp"/ --no-same-owner download-utilities.sh
  echo "db37a86921257a9a70b6e60e1d2774b97dc248842737ad99dabae9131adf4a68  ${exec_tmp}/download-utilities.sh" | \
  checksum_file || return $?
  chmod 755 "${exec_tmp}/download-utilities.sh"
)

cleanup_on() {
  if [ -d "${exec_tmp:-}" ]; then
    rm -rf "${exec_tmp}"
  fi
}

update() (
  download-utilities.sh --update \
    ~/git/home/misc/download-utilities.yml
)

checksum() (
  export skip_checksum=1
  os="$1" arch="$2" download-utilities.sh \
    ~/git/home/misc/download-utilities.yml

  download-utilities.sh --checksum \
    ~/git/home/misc/download-utilities.yml \
    > ~/git/home/misc/checksums/"$1-$2".sha256
)

trap cleanup_on EXIT
create_tmp
install_download_sh
export PATH="$exec_tmp:$PATH"

force_yq=1 update

# Update every OS and architecture except for this one
for os in Linux Darwin; do
  for a in x86_64 aarch64; do
    arch="$a"
    if [ "$os" = Darwin ] && [ "$a" = aarch64 ]; then
      arch=arm64
    fi
    if [ "$os" = "$(uname)" ] && [ "$arch" = "$(arch)" ]; then
      continue
    fi
    checksum "$os" "$arch"
  done
done

# Update this OS and architecture last
checksum "$(uname)" "$(arch)"
