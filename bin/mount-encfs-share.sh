#!/bin/bash
#Sam Gleske
#Wed Aug 13 00:05:24 EDT 2014
#Fedora release 16 (Verne)
#Linux 3.6.11-4.fc16.x86_64 x86_64
#GNU bash, version 4.2.37(1)-release (x86_64-redhat-linux-gnu)

#USAGE
#  mount-encfs-share.sh sample_folder

#CONVENTION OVER CONFIGURATION
#  For this script encfs encrypted folders will always follow a convention.
#
#  sample_folder (unencrypted)
#  .encfs_sample_folder (encrypted vault in the same directory)

#If not running as root then switch to it
if [ ! "${USER}" = "root" ]; then
  sudo -s $0 "$@"
  exit
fi

#remove trailing slash if in path
mount_point="${1%/}"

#check if already mounted
if mount | grep "${mount_point}" &> /dev/null; then
  echo "${mount_point} appears to be mounted."
  exit 1
fi

#fix relative path if not relative nor absolute path given
if ! echo "${mount_point}" | grep '^.\{0,2\}/' &> /dev/null; then
  #force absolute in that case for parameter expansion to work
  mount_point="${PWD}/${mount_point}"
#if relative path then force absolute
elif echo "${mount_point}" | grep '^.\{1,2\}/' &> /dev/null; then
  mount_point="${PWD}/${mount_point}"
fi

#check if mount point exists else create it
if [ ! -d "${mount_point}" ]; then
  mkdir -p "${mount_point}"
  #make ownership of the sudoing user
  if [ ! -z "${SUDO_USER}" ]; then
    chown ${SUDO_USER}\: "${mount_point}"
  fi
  #useful if dir is unmounted
  chmod 000 "${mount_point}"
fi

#set the encrypted_vault path based on the mount_point
dir_name="${mount_point%/*}"
base_name="${mount_point##*/}"
encrypted_vault="${dir_name}/.encfs_${base_name}"

#check if encrypted vault folder exists and if not then create one
if [ ! -d "${encrypted_vault}" ]; then
  mkdir -p "${encrypted_vault}"
  #make ownership of the sudoing user
  if [ ! -z "${SUDO_USER}" ]; then
    chown ${SUDO_USER}\: "${encrypted_vault}"
  fi
fi

#mount the encrypted vault FINALLY
encfs --public "${encrypted_vault}" "${mount_point}"
