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

#check for help option
for x in "$@"; do
  case $x in
    -h|--help)
      #helpdoc was created by reading source of man pages crontab(1) and
      #apt-cache(8)
      man -l - <<EOF
.TH fastest_mirror.sh 1 "28 November 2015"
.UC 4
.SH NAME
.B fastest_mirror.sh
\\- Find the fastest mirror for Ubuntu updates.
.SH SYNOPSIS
.B fastest_mirror.sh
[
.B \\-u
] [
.B \\-\\-update
]
.SH DESCRIPTION
.I fastest_mirror.sh
is a program used to determine the fastest Ubuntu update mirrors for this
network.  It uses
.IR netselect (1)
to inquire latency and throughput for mirrors found at
https://launchpad.net/ubuntu/+archivemirrors relative to the current network of
this machine.
.SH "OPTIONS"
.PP
If this script is run without options then, by default, it will print out the
fastest mirrors without modifying any system files.
.PP
\\fB\\-h\\fR, \\fB\\-\\-help\\fR
.RS 4
Show this help document.
.RE
.PP
\\fB\\-u\\fR, \\fB\\-\\-update\\fR
.RS 4
Update
.I sources.list
with the fastest mirror.  NOTE: this option modifies system files.
.RE
.SH "SEE ALSO"
\\fBnetselect\\fR(1),
\\fBsources.list\\fR(5)
.br
http://askubuntu.com/questions/39922/how-do-you-select-the-fastest-mirror-from-the-command-line/141536#141536
.br
https://launchpad.net/ubuntu/+archivemirrors
.SH "AUTHOR"
Sam Gleske https://sam.gleske.net/
EOF
      exit 1
      ;;
  esac
done

if [ ! -e '/usr/bin/netselect' ]; then
  echo 'Error: netselect package missing.'
  echo 'Download: https://packages.debian.org/stable/net/netselect'
  exit 1
fi

if [ ! 'root' = "$USER" ]; then
  echo 'Launching script as administrator.'
  sudo -- "$0" "$@"
  exit $?
fi

#option parsing
auto_update=false
while [ "$#" -gt '0' ]; do
  case $1 in
    -h|--help)
      showhelp=true
      break
      ;;
    -u|--update)
      auto_update=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done


if ${auto_update}; then
  #determine if Ubuntu
  if type -f lsb_release &> /dev/null && [ ! 'Ubuntu' = "$(lsb_release -si)" ]; then
    echo "Not Ubuntu so there's not much reason to run this script."
    exit 1
  fi

  if [ ! -e "/etc/apt/sources.list.old" ]; then
    cp /etc/apt/sources.list /etc/apt/sources.list.old
  fi

  #check up to 200 different servers for fastest internet speeds
  #choose the fastest one as the $fastest_mirror
  fastest_mirror="$(netselect -v -s200 -t20 $(wget -q -O- https://launchpad.net/ubuntu/+archivemirrors | grep -P -B8 "statusUP|statusSIX" | grep -o -P "(f|ht)tp.*\"" | tr '"\n' '  ') | head -n1 | awk '{print $2}' )"

  #create a temporary file with the fastest mirror
  sed "s#http://us.archive.ubuntu.com/ubuntu/#${fastest_mirror}#" /etc/apt/sources.list.old > /tmp/sources.list

  if ! diff /tmp/sources.list /etc/apt/sources.list &> /dev/null; then
    echo "Updating sources.list to new fastest mirror: ${fastest_mirror}"
    mv /tmp/sources.list /etc/apt/sources.list
  else
    echo "Fastest mirror remains: ${fastest_mirror}"
    rm /tmp/sources.list
  fi
  echo 'The originally installed sources.list is located at /etc/apt/sources.list.old'
else
  netselect -v -s200 -t20 $(wget -q -O- https://launchpad.net/ubuntu/+archivemirrors | grep -P -B8 "statusUP|statusSIX" | grep -o -P "(f|ht)tp.*\"" | tr '"\n' '  ')
fi
