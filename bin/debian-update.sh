#!/bin/bash

# Script:       update.sh
# Purpose:      Update software packages,
#               respect new dependencies,
#               clean up obsolete packages
# Configuration files:
#   /etc/crontab           execution time
#   /etc/apt/sources.list  apt-get configuration
# Author:     Sven Claussner, 2014
# Contrib:    Sam Gleske, 2014

update_logs="/var/log/update"

if [ ! -d "${update_logs}" ]; then
  mkdir -p "${update_logs}"
fi

apt-get update 1> "${update_logs}/update.log" 2> "${update_logs}/update.err" && 
apt-get -fyq dist-upgrade 1> "${update_logs}/update.log" 2> "${update_logs}/update.err" &&
apt-get -yq autoclean 1> "${update_logs}/update.log" 2> "${update_logs}/update.err" &&
apt-get -yq autoremove 1> "${update_logs}/update.log" 2> "${update_logs}/update.err" &&
shutdown -r now 1> "${update_logs}/update.log" 2> "${update_logs}/update.err" 
