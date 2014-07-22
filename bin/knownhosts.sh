#!/bin/bash
#Created by Sam Gleske
#Tue Aug  6 14:12:05 EDT 2013
#Ubuntu 12.04.2 LTS
#Linux 3.8.0-27-generic x86_64
#GNU bash, version 4.2.25(1)-release (x86_64-pc-linux-gnu)
#OpenSSH_5.9p1 Debian-5ubuntu1.1, OpenSSL 1.0.1 14 Mar 2012

#Find known_hosts key issues given a list of server names in stdin

STATUS=0

while read line;do
  if ! ssh-keygen -H -F $line | grep "$(ssh-keyscan -t rsa ${line} 2>/dev/null | awk '{print $3}')" &> /dev/null;then
    echo $line
    STATUS=1
  fi
done

exit ${STATUS}
