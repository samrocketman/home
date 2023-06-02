#!/bin/bash

set -euo pipefail

if [ ! -d ~/usr/share/yml-install-files ]; then
  mkdir -p ~/usr/share ~/usr/bin
  pushd ~/usr/share
  git clone https://github.com/samrocketman/yml-install-files.git
  popd
fi

create_tmp() {
  export exec_tmp
  exec_tmp="$(mktemp -d)"
  touch "$exec_tmp"/file
  chmod 755 "$exec_tmp"/file
  if [ ! -x "$exec_tmp"/file ]; then
    rm -r "$exec_tmp"
  else
    return
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

cleanup_on() {
  if [ -d "${exec_tmp:-}" ]; then
    rm -rf "${exec_tmp}"
  fi
}

update() (
  ~/usr/share/yml-install-files/download-utilities.sh --update \
    ~/git/home/misc/download-utilities.yml
)

checksum() (
  export skip_checksum=1
  os="$1" arch="$2" ~/usr/share/yml-install-files/download-utilities.sh \
    ~/git/home/misc/download-utilities.yml

  ~/usr/share/yml-install-files/download-utilities.sh --checksum \
    ~/git/home/misc/download-utilities.yml \
    > ~/git/home/misc/checksums/"$1-$2".sha256
)

trap cleanup_on EXIT
create_tmp
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
