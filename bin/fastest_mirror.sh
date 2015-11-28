#!/bin/bash
#Created by Sam Gleske
#Sat Nov 28 12:32:08 PST 2015
#http://askubuntu.com/questions/39922/how-do-you-select-the-fastest-mirror-from-the-command-line/141536#141536
#Ubuntu 14.04.3 LTS
#Linux 3.13.0-68-generic x86_64
#GNU bash, version 4.3.11(1)-release (x86_64-pc-linux-gnu)
#grep (GNU grep) 2.16
#tr (GNU coreutils) 8.21
#GNU Wget 1.15 built on linux-gnu.
#netselect 0.3.ds1-26
#Description:
#  Find the fastest mirror for Ubuntu updates


if [ ! -e '/usr/bin/netselect' ]; then
  echo 'Error: netselect package missing.'
  echo 'Download: https://packages.debian.org/stable/net/netselect'
  exit 1
fi

if [ ! 'root' = "$USER" ]; then
  echo 'Launching script as administrator.'
  sudo "$0" "$@"
  exit $?
fi

netselect -v -s200 -t20 `wget -q -O- https://launchpad.net/ubuntu/+archivemirrors | grep -P -B8 "statusUP|statusSIX" | grep -o -P "(f|ht)tp.*\"" | tr '"\n' '  '`
