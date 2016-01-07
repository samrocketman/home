#!/bin/bash
#Sam Gleske
#github.com/sag47
#Sat Mar 29 14:13:27 EDT 2014
#Fedora release 16 (Verne)
#Linux 3.6.11-4.fc16.x86_64 x86_64
#GNU bash, version 4.2.37(1)-release (x86_64-redhat-linux-gnu)
#gpg (GnuPG) 1.4.13
#DESCRIPTION
#  This script will individually encrypt files in a folder
#  using gpg and then generate a sha1sum of all encrypted
#  files (*.gpg).
#USAGE
#  gpg_encrypt_individual_files.sh dir/

#a space separated list of recipient key IDs
#this value can be overridden by environment
recipient_list="${recipient_list:-}"

#remove the original unencrypted file?
#this value can be overridden by environment
remove_original="${remove_original:-true}"

#skip files that already have an encrypted equivalent?
#i.e. this will replace the encrypted file equivalent if it already exists
#this value can be overridden by environment
skip_encrypted="${skip_encrypted:-false}"

#create checksums for the files in each directory.
#Each directory will contain a file call sha1sum.txt
#this value can be overridden by environment
create_checksums="${create_checksums:-true}"

#Do you want to sign the files too?; this value can be overridden by environment
sign_encrypted_file="${sign_encrypted_file:-false}"

#Additional options for gpg commands
#gpg_opts="${gpg_opts:---use-agent}"

#DO NOT EDIT ANY MORE VARIABLES
#this will individually encrypt all files in the folder
#this value can be overridden by environment
if [ -z "${folder_to_encrypt}" ]; then
  folder_to_encrypt="${1}"
fi

#if the end of the file or name matches an ignore_rule,
#then it will not be encrypted; this value can be overridden by environment
if [ "${#ignore_rules[@]}" -eq "0" ]; then
  ignore_rules=('.gpg' 'sha1sum.txt' '.checksumrequired' '.sig')
fi


if [ -z "${folder_to_encrypt}" -o ! -d "${folder_to_encrypt}" ]; then
  echo "Must provide a valid folder as an argument!"
  exit 1
elif [ -z "${recipient_list}" ]; then
  echo "recipient_list environment variable is not set!"
  echo "You should set it in ~/.bashrc and/or ~/.bash_profile."
  echo "It is a space separated list of GPG key IDs."
  exit 1
fi

#disable globbing
set -o noglob
#exit script on first error
set -e

#check for dependent utilities
deps=(gpg sha1sum find rm sed)
for x in ${deps[*]}; do
  if ! which $x &> /dev/null; then
    echo "Missing utility $x"
    exit 1
  fi
done

#build a recipient list
recipients=""
for x in ${recipient_list};do recipients="${recipients} --recipient ${x}";done

#build the ignore rules for the find command
ignore_expression=""
for x in ${ignore_rules[@]}; do
  ignore_expression="${ignore_expression} -path *${x} -prune -o "
done

#use find command to find files to encrypt
find "${folder_to_encrypt}" ${ignore_expression} -type f -print \
  | while read x; do
  dir="${x%/*}"
  file="${x##*/}"
  (
    #subshell
    #exit subshell on first error
    set -e
    cd "${dir}"
    if [ -e 'sha1sum.txt.sig' ] && ! gpg --verify "sha1sum.txt.sig" &> /dev/null; then
      echo "Signature validation failed: ${dir}/sha1sum.txt"
      echo "Aborting."
      exit 1
    fi
    #remove encrypted file equivalent if it exists
    ! ${skip_encrypted} && [ -f "${file}.gpg" ] && rm -f -- "${file}.gpg"
    if ! ${skip_encrypted} \
      || [ "${skip_encrypted}" = "true" -a ! -f "${file}.gpg" ]; then
      #sign (-d) encrypt (-e) the file (output is filename.gpg)
      if ${sign_encrypted_file}; then
        gpg ${gpg_opts} -s -e ${recipients} -- "${file}"
      else
        gpg ${gpg_opts} -e ${recipients} -- "${file}"
      fi
      echo -n "encrypted ${x}"
      if ${remove_original}; then
        rm -f -- "${file}"
        echo " and removed original."
      else
        echo ""
      fi
      touch -- "${file}.gpg.checksumrequired"
    fi
  )
done
${create_checksums} && echo "Checksumming files in ${folder_to_encrypt}..."
#create a checksum of each file in the folder
#but ONLY do it to encrypted files that have changed
#i.e. has a *.gpg.checksumrequired file
${create_checksums} && find "${folder_to_encrypt}" -type d | while read x; do
  (
    #subshell
    #exit subshell on first error
    set -e
    cd "${x}"
    if [ -e 'sha1sum.txt.sig' ] && ! gpg --verify "sha1sum.txt.sig" &> /dev/null; then
      echo "Signature validation failed: ${x}/sha1sum.txt"
      echo "Aborting."
      exit 1
    fi
    #create sha1sum.txt file if it doesn't exist
    [ ! -f "sha1sum.txt" ] && touch sha1sum.txt
    find . -maxdepth 1 -type f -name '*.gpg.checksumrequired' -printf '%f\n' \
      | while read esum; do
      #delete the old entry from the sha1sum.txt file
      echo "Checksumming ${x}/${esum%\.checksumrequired}"
      expression="$(echo "${esum%\.checksumrequired}" \
        | sed 's/\[/\\\[/g' \
        | sed 's/\]/\\\]/g')"
      sed -i "/\w\s\+${expression}/ d" sha1sum.txt
      #append the new sum to the sha1sum.txt file
      sha1sum -- "${esum%\.checksumrequired}" >> sha1sum.txt
      #remove the checksumrequired file
      rm -f -- "${esum}"

      #update the signature if it exists
      if [ -e 'sha1sum.txt.sig' ]; then
        \rm -f sha1sum.txt.sig
        gpg --output sha1sum.txt.sig --detach-sign -- sha1sum.txt
      fi
    done
  )
done
