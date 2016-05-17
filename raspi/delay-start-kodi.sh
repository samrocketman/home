#!/bin/bash

function startkodi() (
  count=5
  SHIFT=0
  while [ "$count" -gt 0 -a "$SHIFT" = "0" ]; do
    echo "(Press SHIFT to cancel) Starting kodi in... $count"
    ((count--))
    sleep 1
    if ! getkey /dev/input/by-id/*-kbd lshift; then
      SHIFT=1
    fi
  done
  if [ "$SHIFT" -eq 0 ]; then
    echo "Starting kodi..."
    kodi
  else
    echo "Canceled starting kodi."
  fi
)

if ! type -pP kodi; then
  echo "kodi not installed."
  exit 1
fi

startkodi
