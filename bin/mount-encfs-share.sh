#!/bin/bash -e
#Created by Sam Gleske (github @samrocketman)
#Wed Aug 13 00:05:24 EDT 2014
#Ubuntu 14.04.1 LTS
#Linux 3.13.0-35-generic x86_64
#GNU bash, version 4.3.11(1)-release (x86_64-pc-linux-gnu)

#USAGE
#  mount-encfs-share.sh sample_folder
#  mount-encfs-share.sh -h

PROGNAME="${0##*/}"
PROGVERSION="0.2"
DEFAULT_ENCFS_OPTS="${DEFAULT_ENCFS_OPTS:---public}"

function usage() {
cat <<EOF
${PROGNAME} ${PROGVERSION} - MIT License by Sam Gleske (github @samrocketman)

SYNOPSIS
    ${PROGNAME} [ENCFS_OPTS] FOLDER

DESCRIPTION
    This is a wrapper script around the encfs utility which automatically
    creates and mounts encfs volumes.

OPTIONS:
    [ENCFS_OPTS]              One or more options to be passed through to the
                              encfs utility.  See encfs(1) man page for options.

    FOLDER                    The folder to mount or create an encrypted volume.
                              This must always be the last argument.

CONVENTION OVER CONFIGURATION
    For this script encfs encrypted folders will always follow a convention for
    folders it is mounting.

    sample_folder (unencrypted)
    .encfs_sample_folder (encrypted vault in the same directory)

    For example lets say you have a folder: "sample_folder".  It is intended to
    be an encfs mount point where the unencrypted contents are accessed.  The
    encrypted vault will be located at: ".encfs_sample_folder".  If the
    encrypted vault doesn't exist then this script will automatically create it.

EXAMPLES
    Mount an encrypted volume (or if it doesn't exist create it).
        ${PROGNAME} somevolume

    Mount an encrypted volume and read the password from stdin.
        echo password | ${PROGNAME} -S somevolume

    Unmount the encfs volume.
        fusermount -u somevolume
EOF
}

#since we automatically switch to root try to figure out if the help doc is
#being invoked.  If so might as well display help instead of trying to be root.
if echo "$@" | grep -- '-h$\|--help$' &> /dev/null; then
  usage
  exit 1
fi

#If not running as root then switch to it if --public option used.
if echo "${DEFAULT_ENCFS_OPTS}" | grep -- '--public' &> /dev/null \
  || echo "${ENCFS_OPTS}" | grep -- '--public' &> /dev/null; then

  if [ ! "${USER}" = "root" ]; then
    sudo -s "$0" "$@"
    exit
  fi
fi

#Read any potential options
while true; do
  case "$1" in
    -h|--help)
        usage
        exit 1
      ;;
  esac
  if [ "$#" -eq "1" ]; then
    break
  fi
  ENCFS_OPTS="${ENCFS_OPTS} $1"
  shift
done

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
    chown "${SUDO_USER}"\: "${mount_point}"
  fi
  #useful if dir is unmounted
  if [ "${USER}" = "root" ]; then
    chmod 000 "${mount_point}"
  fi
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
    chown "${SUDO_USER}"\: "${encrypted_vault}"
  fi
fi

#mount the encrypted vault FINALLY
#the <&0 reads from stdin in case the -S option is used in $ENCFS_OPTS
encfs ${DEFAULT_ENCFS_OPTS} ${ENCFS_OPTS} "${encrypted_vault}" "${mount_point}" <&0
