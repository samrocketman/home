#!/bin/bash
#Original version by Brian Clapper (github @bmc)
#Modified by Sam Gleske (github @samrocketman)
#Wed Jul 23 22:01:30 EDT 2014
#Fedora release 16 (Verne)
#Linux 3.6.11-4.fc16.x86_64 x86_64
#GNU bash, version 4.2.37(1)-release (x86_64-redhat-linux-gnu)
#encfs version 1.7.4

######################################################################
#USAGE
#  Mount a vault
#    mount-encfsvault.sh
#
#  Unmount a vault
#    umount-encfsvault.sh

#DESCRIPTION
#  A simple script to mount and unmount an encfs filesystem.
#  This command executes different

#INSTALL
#  ln -s /path/to/encfs-vault.sh ~/bin/mount-encfsvault.sh
#  ln -s /path/to/encfs-vault.sh ~/bin/umount-encfsvault.sh
######################################################################

if [ -z "${1}" ];then
  source_dir="${HOME}/.vault"
else
  source_dir="${1}"
fi

if [ -z "${2}" ];then
  mount_point="${HOME}/mnt/vault"
else
  mount_point="${2}"
fi

case "${0##*/}" in
    mount*)
        encfs "${source_dir}" "${mount_point}"
        rc=$?
        ;;

    umount*)
        sudo umount "${mount_point}"
        rc=$?
        ;;

    *)
        echo "Huh? Invoked as $0?" >&2
        rc=1
        ;;
esac

exit ${rc}
