#!/bin/bash
#Sam Gleske
#Wed Jun 18 22:57:45 EDT 2014
#Fedora release 16 (Verne)
#Linux 3.6.11-4.fc16.x86_64 x86_64
#GNU bash, version 4.2.37(1)-release (x86_64-redhat-linux-gnu)
#sha1sum (GNU coreutils) 8.12
#gpg (GnuPG) 1.4.13

#USAGE:
#  gpg_validate_sha1sums.sh DIRECTORY

#DESCRIPTION
#  This script will iterate through a gpg_encrypt_individual_files.sh
#  encrypted directory and validate the sha1sum.txt.sig signatures.
#  This is intended to check the signatures against all signed
#  sha1sum.txt files and fail the validation if no signatures are
#  provided.

if [ -z "$!" -a ! -d "$1" ]; then
  echo "Error: must provide a directory as an argument." 1>&2
  exit 1
fi

find "$1" -type d | while read x; do
  set -e
  pushd "$x" &> /dev/null
  if [ ! -f sha1sum.txt.sig ]; then
    echo -e "\nLocation: $x" 1>&2
    echo -e "Error: No sha1sum.txt.sig!\n" 1>&2
    exit 1
  fi
  if ! gpg --verify "sha1sum.txt.sig"; then
    echo -en "\nLocation: $x\n" 1>&2
    echo -e "Error: sha1sum.txt.sig contains a bad signature.\n" 1>&2
    exit 1
  fi
  popd &> /dev/null
done || exit 1

echo -e "\nAll signatures exist and validated!\n" 1>&2
