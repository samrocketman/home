#!/bin/bash
#Sam Gleske
#Wed Jun 18 22:57:45 EDT 2014
#Fedora release 16 (Verne)
#Linux 3.6.11-4.fc16.x86_64 x86_64
#GNU bash, version 4.2.37(1)-release (x86_64-redhat-linux-gnu)
#sha1sum (GNU coreutils) 8.12
#gpg (GnuPG) 1.4.13

#USAGE:
#  gpg_sign_sha1sums.sh DIRECTORY

#DESCRIPTION
#  This script will iterate through a gpg_encrypt_individual_files.sh
#  encrypted directory and sign all of the sha1sum.txt files.  This
#  is intended for ensuring the integrity of all checksummed files
#  when, for example, uploading your encrypted files to a cloud
#  filesharing service.

if [ -z "$!" -a ! -d "$1" ];then
  echo "Error: must provide a directory as an argument." 1>&2
  exit 1
fi

find "$1" -type f -name 'sha1sum.txt' | while read x;do
  gpg --output "$x.sig" --detach-sign "$x"
  echo "Signed $x" 1>&2
done
