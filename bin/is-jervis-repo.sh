#!/bin/bash
#Created by Sam Gleske
#Tue Oct 26 17:03:28 EDT 2021
#DESCRIPTION:
#    Checks if the current repository has a Jervis integration.
#    Learn more at https://github.com/samrocketman/jervis

set -eo pipefail

TMP_DIR=$(mktemp -d)

exec 3>&1 4>&2 >/dev/null 2>&1
2> /dev/null

function answer() {
	if [ "$1" = 0 ]; then
		echo yes >&3
	else
		echo no >&3
	fi
	rm -rf "$TMP_DIR"
}

trap 'answer $?' EXIT

git clone --depth 1 "$PWD" "$TMP_DIR/repo"

[ -f "$TMP_DIR"/repo/.jervis.yml ]
