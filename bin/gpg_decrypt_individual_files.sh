#!/bin/bash
#Sam Gleske
#github.com/sag47
#Sat Mar 29 19:51:06 EDT 2014
#Fedora release 16 (Verne)
#Linux 3.6.11-4.fc16.x86_64 x86_64
#GNU bash, version 4.2.37(1)-release (x86_64-redhat-linux-gnu)
#gpg (GnuPG) 1.4.13
#DESCRIPTION
#  This script will decrypt all *.gpg files located in a sub directory.

#remove the original encrypted file?
#this value can be overridden by environment
remove_original="${remove_original:-true}"

#Additional options for gpg commands
#gpg_opts="${gpg_opts:---use-agent}"

#DO NOT EDIT ANY MORE VARIABLES
#exit on first error
set -e

#check for dependent utilities
deps=(gpg sha1sum find rm sed)
for x in ${deps[*]}; do
  if ! type -p $x &> /dev/null; then
    echo "Missing utility $x"
    exit 1
  fi
done

#this will individually decrypt all files in the folder
#this value can be overridden by environment
folder_to_decrypt="${folder_to_decrypt:-${1%/}}"

if [ -z "${folder_to_decrypt}" -o ! -d "${folder_to_decrypt}" ]; then
  echo "Must provide a valid folder as an argument!"
  exit 1
fi

#decrypt all individually encrypted files in the folder
find "${folder_to_decrypt}" -type f -name '*.gpg' | while read x; do
  echo "${x}" | gpg ${gpg_opts} --multifile --decrypt --
  echo -n "decrypted ${x}"
  if ${remove_original}; then
    rm -f -- "${x}"
    echo " and removed original."
  else
    echo ""
  fi
done

#NOTE THIS METHOD CAUSES TWICE THE SPACE NEEDED FOR DECRYPTION
#primarily because it decrypts all of the files... and then removes
#decrypt all individually encrypted files in the folder
#find "${folder_to_decrypt}" -type f -name '*.asc' | gpg --multifile --decrypt
#remove encrypted files
#find "${folder_to_decrypt}" -type f -name '*.asc' -exec rm -f {} \;
#remove sha1sum.txt checksum files
#find "${folder_to_decrypt}" -type f -name 'sha1sum.txt' -exec rm -f {} \;
