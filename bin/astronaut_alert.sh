#!/bin/bash
#Fedora release 16 (Verne)
#Linux 3.6.11-4.fc16.x86_64 x86_64
#GNU bash, version 4.2.37(1)-release (x86_64-redhat-linux-gnu)
#curl 7.21.7
#mailx 12.5 7/5/10
#gunzip (gzip) 1.4

#DESCRIPTION
#  Alert me with an email when an Astronaut job becomes available.
#  I want to go into space.

#Schedule check every day at 9am and 3pm.
#0 9,15 * * * /home/sam/bin/astronaut_alert.sh

cookies_file="/tmp/nasa.txt"

keyword="Astronaut"

if ! curl -c "$cookies_file" \
  -k "https://www.usajobs.gov/Search?Keyword=${keyword}" \
  -H 'Host: www.usajobs.gov' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:29.0) \
  Gecko/20100101 Firefox/29.0' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
  -H 'Accept-Language: en-US,en;q=0.5' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H 'DNT: 1' \
  -H 'Connection: keep-alive' 2> /dev/null \
  | gunzip \
  | grep -i 'no jobs' &> /dev/null; then

  if type -P mail; then
    echo -e "See Astronaut jobs - \
      https://www.usajobs.gov/Search?Keyword=${keyword}" \
      | mail -s "Astronaut Jobs available!" sam.mxracer@gmail.com
  else
    echo "See Astronaut jobs - https://www.usajobs.gov/Search?Keyword=${keyword}"
  fi
fi
