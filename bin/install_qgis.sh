#!/bin/bash
# Created by Sam Gleske
#   Sun Oct 20 15:29:03 EDT 2019
#   Ubuntu 18.04.3 LTS
#   Linux 5.0.0-31-generic x86_64
# DESCRIPTION
#   This script configures the QGIS repository and installs the latest stable
#   QGIS software for Ubuntu LTS and its derivatives (like Pop! OS LTS).
# USAGE
#   Download install_qgis.sh to /home/$USER.
#   Install latest QGIS release.
#     bash install_qgis.sh
#   Alternately, install long-term QGIS release.
#     USE_LTR=1 bash install_qgis.sh
# ABOUT QGIS
#   Learn more about QGIS - https://qgis.org/
#   QGIS is a professional GIS application.  Create, edit, visualise, analyze
#   and publish geospatial information.
set -euxo pipefail

#
# FUNCTIONS
#
function add_qgis_repository() {
  local KEYID=51F523511C7028C3
  if grep -qrFl -- qgis.org /etc/apt/sources.list*; then
    echo 'QGIS repository already installed.'
    return
  fi
  if [ -z "$(apt-key finger "${KEYID}")" ]; then
    if ! gpg --fingerprint "${KEYID}"; then
      wget -O - https://qgis.org/downloads/qgis-2019.gpg.key | gpg --import
    fi
    gpg --export --armor "${KEYID}" | sudo apt-key add -
  fi
  if [ -n "${USE_LTR:-}" ]; then
    sudo apt-add-repository https://qgis.org/ubuntu-ltr
  else
    sudo apt-add-repository https://qgis.org/ubuntu
  fi
}

function install_qgis() {
  sudo apt-get update
  sudo apt-get install qgis qgis-plugin-grass qgis-server
}

#
# MAIN EXECUTION
#
add_qgis_repository
install_qgis
