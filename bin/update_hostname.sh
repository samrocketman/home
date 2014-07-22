#!/bin/bash
#Sam Gleske
#Fri Feb 14 15:46:16 EST 2014
#Ubuntu 13.10
#Linux 3.11.0-12-generic x86_64
#GNU bash, version 4.2.45(1)-release (x86_64-pc-linux-gnu)
#DESCRIPTION:
#  To be used in Ubuntu Server VM.  When cloning a VM the hostname
#  should be updated.  This is a small script to update the hostname.

if [ ! "$USER" = "root" ];then
  echo "Must be root!"
  exit 1
fi
if [ -z "$1" ];then
  echo "Must provide hostname as arg!"
  echo "Usage:"
  echo "  update_hostname.sh myhost"
  exit 1
fi
currenthost="$(head -n1 /etc/hostname)"
sed -i 's/'"$currenthost"'/'"$1"'/g' /etc/hostname
sed -i 's/'"$currenthost"'/'"$1"'/g' /etc/hosts
hostname $1
