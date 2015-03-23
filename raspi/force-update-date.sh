#!/bin/bash
#Created by Sam Gleske
#Sat Mar 21 17:32:10 EDT 2015
#Raspbian GNU/Linux 7 \n \l
#Linux 3.18.7-v7+ armv7l
#GNU bash, version 4.2.37(1)-release (arm-unknown-linux-gnueabihf)

#DESCRIPTION
#  Force update the date.

#optionally remove the fake date-time on boot because the raspberry pi has no
#internal clock.
#update-rc.d fake-hwclock remove
#update-rc.d hwclock.sh remove

### BEGIN INIT INFO
# Provides:          force-update-date
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Synchronize time with us.pool.ntp.org.
### END INIT INFO

set -e

#only synchronize on startup
if [ "${1:-}" = "start" ];then
  /bin/echo "Synchronize time with us.pool.ntp.org."
  /usr/sbin/ntpdate -s us.pool.ntp.org
fi
