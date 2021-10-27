#!/bin/bash
#Created by Sam Gleske
#Tue Oct 26 17:03:28 EDT 2021
#DESCRIPTION:
#    Gets the total number of lines added to a repository since the initial
#    commit
# NOTE:
#    4b825dc642cb6eb9a060e54bf8d69288fbee4904 is the id of the "empty tree" in
#    Git and it's always available in every repository.
# EXAMPLE USAGE:
#    Get total lines.
#        get-repository-lines-added.sh
#    Get lines by one or more filetypes.
#        get-repository-lines-added.sh java,py,groovy,js


exec 3>&1 4>&2 >/dev/null 2>&1
#exec 3>&1 4>&2
set -eo pipefail

function expand_extensions() {
  echo "$1" | awk -F, '{for(i=1; i<=NF; i++) print "*."$i}'
}

function git_diff() {
  if [ -n "${1:-}" ]; then
    expand_extensions "$1" | xargs -- git diff --shortstat 4b825dc642cb6eb9a060e54bf8d69288fbee4904 HEAD --
  else
    git diff --shortstat 4b825dc642cb6eb9a060e54bf8d69288fbee4904 HEAD
  fi
  # insert a blank line for empty count compatibility
  echo
}

trap '[ $? = 0 ] || echo 0 >&3' EXIT
git_diff "${1:-}" | \
  sed 's/[^0-9,]*//g' | \
  awk -F, '!($2 > 0) {$2="0"};!($3 > 0) {$3="0"}; {print $2-$3}' |
  head -n1 >&3
