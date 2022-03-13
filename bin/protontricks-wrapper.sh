#!/bin/bash
# Created by Sam Gleske
# Sun Jan  2 12:53:44 EST 2022
# Ubuntu 18.04.6 LTS
# Linux 5.4.0-91-generic x86_64
# GNU bash, version 4.4.20(1)-release (x86_64-pc-linux-gnu)
# Python 3.6.9

set -eo pipefail

if [ ! -f ~/usr/share/protontricks-venv/bin/activate ]; then
  if [ -d ~/usr/share/protontricks-venv ]; then
    rm -rf ~/usr/share/protontricks-venv
  fi
  mkdir -p ~/usr/share
  python3 -m venv ~/usr/share/protontricks-venv
fi

source ~/usr/share/protontricks-venv/bin/activate

if ! type -P protontricks &> /dev/null; then
  pip install protontricks
fi

protontricks "$@"
