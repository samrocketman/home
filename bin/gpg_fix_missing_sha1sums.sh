#!/bin/bash
#Sam Gleske
#Wed Jan  6 18:00:46 PST 2016
#Ubuntu 14.04.3 LTS
#Linux 3.13.0-74-generic x86_64
#GNU bash, version 4.3.11(1)-release (x86_64-pc-linux-gnu)
#sha1sum (GNU coreutils) 8.21
#gpg (GnuPG) 1.4.16

#USAGE:
#  gpg_fix_missing_sha1sums.sh DIRECTORY

#DESCRIPTION
#  This script will iterate through a gpg_encrypt_individual_files.sh
#  encrypted directory and fix missing checksums and resign the sha1sum.txt
#  file.  This is basically intended for moving encrypted gpg files to different
#  directories.  When a file is moved the checksumming breaks and nothing can be
#  verified.

if [ -z "$!" -a ! -d "$1" ]; then
  echo "Error: must provide a directory as an argument." 1>&2
  exit 1
fi

find "$1" -type d | while read x; do
  (
    cd "$x"
    if [ -e "sha1sum.txt.sig" ]; then
      #validate the checksum of the signature
      if gpg --verify "sha1sum.txt.sig" &> /dev/null; then
        #validation complete meaning we can modify with confidence
        #remove if file is missing
        sed -- 's/^[a-f0-9]\+  //' sha1sum.txt | while read y; do
          if [ ! -e "$y" ]; then
            #remove missing file from sha1sum.txt
            expression="$(echo "${y}" \
              | sed 's/\[/\\\[/g' \
              | sed 's/\]/\\\]/g')"
            sed -i -- "/\w\s\+${expression}/ d" sha1sum.txt
            echo "Removed missing file ${y} from ${x}/sha1sum.txt"
            \rm -f sha1sum.txt.sig
          fi
        done

        #check if there are any new gpg files that sha1sum.txt isn't tracking
        find . -maxdepth 1 -type f -name '*.gpg' -printf '%f\n' | while read y; do
          if ! grep -F -- "$y" sha1sum.txt &> /dev/null; then
            sha1sum -- "$y" >> sha1sum.txt
            echo "Checksummed ${y} in ${x}/sha1sum.txt"
            #remove signature because sha1sum.txt must be re-signed.
            \rm -f sha1sum.txt.sig
          fi
        done

        #Too many security implications with the following section.
        #It basically blindly re-checksums failed checksums.
        #That should not be how this script operates.
#        find . -maxdepth 1 -type f -name '*.gpg' -printf '%f\n' | while read y; do
#          if ! ( grep -F -- "$y" sha1sum.txt | sha1sum -c ) &> /dev/null; then
#            echo "$x/$y"
#            #checksum failed so delete old entry
#            expression="$(echo "${y}" \
#              | sed 's/\[/\\\[/g' \
#              | sed 's/\]/\\\]/g')"
#            sed -i "/\w\s\+${expression}/ d" sha1sum.txt
#            #append the new sum to the sha1sum.txt file
#            sha1sum -- "$y" >> sha1sum.txt
#            \rm -f "sha1sum.txt.sig"
#          fi
#        done

        #re-sign the modified sha1sum.txt file
        if [ ! -e "sha1sum.txt.sig" ]; then
          echo "Signed ${x}/sha1sum.txt"
          gpg --output "sha1sum.txt.sig" --detach-sign "sha1sum.txt"
        fi
      else
        echo "Initial validate failed: ${x}/sha1sum.txt.sig"
        echo "Aborting."
        exit 1
      fi
    fi
  )
done
