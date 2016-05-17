#!/bin/bash
#Created by Sam Gleske
#Mon 16 May 18:54:38 PDT 2016
#Raspbian GNU/Linux 8
#Linux 4.4.9-v7+ armv7l
#GNU bash, version 4.3.30(1)-release (arm-unknown-linux-gnueabihf)
#gcc (Raspbian 4.9.2-10) 4.9.2

#DESCRIPTION
#Delay starting kodi for 5 seconds unless SHIFT is pressed.

#Depends on src/getkey.c being compiled and in the $PATH

function shiftkey() (
  #get a device
  device="$(ls -1 /dev/input/by-id/*-kbd | head -n1)"
  if [ ! "$#" -eq 1 ]; then
    return 1
  fi
  getkey $device $1
)

function startkodi() (
  count=5
  SHIFT=0
  while [ "$count" -gt 0 -a "$SHIFT" = "0" ]; do
    echo "(Press SHIFT to cancel) Starting kodi in... $count"
    ((count--))
    sleep 1
    #holding the right or left shift key?
    if ! (shiftkey lshift && shiftkey rshift); then
      SHIFT=1
    fi
  done
  if [ "$SHIFT" -eq 0 ]; then
    echo "Starting kodi..."
    command kodi-standalone
  else
    echo "Canceled starting kodi."
  fi
)

#only start kodi if GUI is not running
if ! pgrep openbox &> /dev/null; then
  if ! type -pP kodi; then
    echo "kodi not installed."
    exit 1
  fi

  startkodi
fi
