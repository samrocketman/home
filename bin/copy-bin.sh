#!/bin/sh
# Created by Sam Gleske
# Tue Nov  7 09:08:34 PM EST 2023
# Ubuntu 22.04.3 LTS
# Linux 6.2.0-36-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)
# Also tested with Alpine Linux 3.18
# MIT Licensed (https://github.com/samrocketman/home)

# DESCRIPTION
#   This script is meant for copying binaries into distroless Docker images.
#   It will copy binaries, shared object linked libraries the binary depends
#   on, and it can additionally copy all symlinks pointing to the binary or
#   shared object dependencies.

# EXAMPLE USAGE
#   Copy to a --prefix base a binary and its shared library linked dependencies
#   (--ldd) and ensure that all sylinks pointing to binary (--bin) are also
#   copied if those links are contained within a linked path (--links)
#
#     copy-bin.sh --prefix /base \
#                 --ldd /bin/busybox \
#                 --bin /bin/busybox \
#                 --links /bin \
#                 --links /sbin \
#                 --links /usr/bin \
#                 --links /usr/sbin
#
#   Alternate copy-bin.sh command doing the same thing.
#
#     copy-bin.sh --prefix /base \
#                 --ldd /bin/busybox \
#                 --links /bin:/sbin:/usr/bin:/usr/sbin

# EXIT CODES
#   exit code 5
#     Help text was shown.
#   exit code 127
#     Utility not found; you must install it because this script depends on it.

stderr() {
  echo "$@" >&2
}

checkutil() {
  if ! type "$1" > /dev/null; then
    type "$1" >&2
  fi
}

# only copy if nothing exists
cp_lite() {
  if [ -e "$prefix$1" ]; then
    return
  fi
  local basepath="`dirname "$1"`"
  mkdir -p "$prefix""$basepath"
  cp -a "$1" "$prefix""$1"
}

help() {
  stderr 'A utility for copying binaries and shared object dependencies.'
  stderr
  stderr 'SYNOPSIS'
  stderr '  copy-bin.sh --prefix PREFIX --ldd LDD [--bin BIN [[--links LINK] ...]]'
  stderr '  copy-bin.sh -p PREFIX -l LDD [-b BIN [[-L LINK] ...]]'
  stderr
  stderr 'OPTIONS'
  stderr '--prefix PREFIX, -p PREFIX'
  stderr '  The destination to copy LDD files and bin symlinks.'
  stderr
  stderr '--ldd LDD, -l LDD'
  stderr '  Read the binary at path LDD, copy it to PREFIX; run ldd utility on'
  stderr '  it and copy all shared object dependencies to PREFIX.'
  stderr
  stderr '--bin  BIN, -b BIN'
  stderr '  Symlinks should match destination bin.  (does not perform copy)'
  stderr '  Defaults to LDD if not specified and --links is specified.'
  stderr
  stderr '--links LINK, -L LINK'
  stderr '  Copy symlink LINK to PREFIX if it points to BIN.  This option can'
  stderr '  be provided multiple times or colon:separated:paths provided.'
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help|-h)
        help
        exit 5
        ;;
      --prefix|-p)
        prefix="$2"
        shift
        shift
        ;;
      --ldd|-l)
        ldd="$2"
        shift
        shift
        ;;
      --bin|-b)
        bin="$2"
        shift
        shift
        ;;
      --links|-L)
        if [ "x$links" = x ]; then
          links="$2"
        else
          links="$links:$2"
        fi
        shift
        shift
        ;;
      *)
        shift
        ;;
    esac
  done
  if [ ! "x$ldd" = x ] && [ "x$bin" = x ] && [ ! "x$links" = x ]; then
    bin="$ldd"
  fi
}

validate_args() {
  local errcode=0
  if [ "x$prefix" = x ]; then
    stderr 'ERROR: --prefix is required but not provided.'
    errcode=5
  elif ! echo "$prefix" | grep '^/' > /dev/null; then
    stderr 'ERROR: --prefix must be a full path and not relative.'
    errcode=5
  fi
  if [ ! "x$ldd" = x ]; then
    if [ ! -f "$ldd" ]; then
      stderr 'ERROR: --ldd must point to a regular file.'
      errcode=5
    fi
  fi
  if [ ! "x$links" = x ]; then
    if [ "x$bin" = x ]; then
      stderr 'ERROR: --links were specified but --bin option not provided.'
      errcode=5
    fi
  fi
  if [ ! "$errcode" = 0 ]; then
    stderr
    stderr 'View source of this script at:'
    stderr "`type "$0"`"
    stderr 'Or see "copy-bin.sh --help" for details.'
  fi
  return "$errcode"
}

deref_symlink() {
  local deref="`readlink "$1"`"
  if [ "x$deref" = x ]; then
    return 1
  fi
  if ! echo "$deref" | grep '^/' > /dev/null; then
    local basepath="`dirname "$1"`"
    deref="$basepath/$deref"
  fi
  if [ ! -e "$deref" ]; then
    return 1
  fi
  echo "$deref"
}

copy_links() {
  if [ "x$bin" = x ]; then
    return
  fi
  local deref=""
  echo "$links" | tr : '\n' | while read -r linkpath; do
    find "$linkpath" -maxdepth 1 -type l | while read -r linkfile; do
      # deref link or ignore dead links
      deref="`deref_symlink "$linkfile"`" || continue
      if [ ! "$bin" = "$deref" ]; then
        continue
      fi
      cp_lite "$linkfile"
    done
  done
}

parse_ldd() {
  awk 'NF == 2 && $1 ~ /^\// { print $1; next }; NF == 4 { print $3 }' | sort -u
}

copy_ldd() {
  if [ "x$ldd" = x ]; then
    return
  fi
  local deref=""
  local base_file_path=""
  ldd "$ldd" 2> /dev/null | parse_ldd | while read -r file; do
    if [ "x$file" = x ]; then
      continue
    fi
    cp_lite "$file"
    # if it was a symlink then copy the link
    if deref="`deref_symlink "$file"`"; then
      cp_lite "$deref"
    fi
  done
  cp_lite "$ldd"
}

#
# MAIN SCRIPT
#

# exit on first error
set -e

# pre-flight check for dependent utilities
checkutil awk
checkutil cp
checkutil dirname
checkutil find
checkutil grep
checkutil ldd
checkutil mkdir
checkutil readlink
checkutil sort
checkutil tr
checkutil xargs

# parse script arguments
#prefix=""
#ldd=""
#bin=""
#links=""
parse_args "$@"
validate_args

if [ ! -d "$prefix" ]; then
  mkdir -p "$prefix"
fi

copy_ldd
copy_links
