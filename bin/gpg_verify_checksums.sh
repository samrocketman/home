#!/bin/bash
#Sam Gleske
#Wed Jun 18 22:57:45 EDT 2014
#Fedora release 16 (Verne)
#Linux 3.6.11-4.fc16.x86_64 x86_64
#GNU bash, version 4.2.37(1)-release (x86_64-redhat-linux-gnu)
#sha1sum (GNU coreutils) 8.12
#gpg (GnuPG) 1.4.13

#USAGE:
#  gpg_verify_checksums.sh DIRECTORY

#DESCRIPTION
#  This program will iterate through an encrypted directory structure
#  to verify the checksum all of the contents.  This is to ensure that
#  the contents of a gpg_encrypt_individual_files.sh encrypted 
#  directory maintains its integrity.  This script eases that process.

if [ -z "$!" -a ! -d "$1" ]; then
  echo "Error: must provide a directory as an argument." 1>&2
  exit 1
fi

#check for dependent utilities
deps=(gpg sha1sum find rm sed)
for x in ${deps[*]}; do
  if ! type -p $x &> /dev/null; then
    echo "Missing utility $x"
    exit 1
  fi
done

find "${1%/}" -type d | while read x; do
  pushd "$x" &> /dev/null
  if [ ! -f sha1sum.txt ]; then
    echo -e "\nLocation: $x" 1>&2
    echo -e "Error: No sha1sum.txt!\n" 1>&2
    exit 1
  fi
  if [ "$(find . -maxdepth 1 -type f \
    | grep -v -- 'sha1sum\.txt\.sig' | wc -l)" -gt "1" ]; then
    if ! sha1sum -c sha1sum.txt; then
      echo -e "\nLocation: $x" 1>&2
      echo "sha1sum failed:" 1>&2
      sha1sum -c sha1sum.txt 2> /dev/null | grep -- FAILED
      echo
      exit 1
    fi
  fi
  popd &> /dev/null
done || exit 1

echo -e "\nAll checksums exist and passed!\n" 1>&2
