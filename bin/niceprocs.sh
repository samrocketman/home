#!/bin/bash
# Created by Sam Gleske
# Created Wed Jan  5 20:37:27 EST 2022
# MIT License - https://github.com/samrocketman/home
# Ubuntu 18.04.6 LTS
# Linux 5.4.0-92-generic x86_64
# GNU bash, version 4.4.20(1)-release (x86_64-pc-linux-gnu)
# ps from procps-ng 3.3.12
# GNU Awk 4.1.4, API: 1.1 (GNU MPFR 4.0.1, GNU MP 6.1.2)
if [ -z "${USER:-}" ]; then
  echo 'This script cannot run because $USER variable is not set.' >&2
  exit 1
fi

ps -eo pid,ppid,user,ni,psr,comm | awk -v user="${USER}" 'NR == 1 {print}; $3 == user && $4 != "0" {print}'
