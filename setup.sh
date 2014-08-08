#!/bin/bash
#Sam Gleske home setup script
#Ubuntu 14.04 LTS \n \l
#Linux 3.13.0-24-generic x86_64
#GNU bash, version 4.3.8(1)-release (x86_64-pc-linux-gnu)
if [ ! -d "${HOME}/git/home" ];then
  echo "ERR: home repo not cloned in ~/git?" >&2
  exit 1
fi

ln -s ~/git/home/dotfiles/.[a-z]* ~/
if [ ! -e "${HOME}/bin" ];then
  ln -s ~/git/home/bin ~/bin
fi

grep '.bashrc_custom' ~/.bashrc &> /dev/null || echo '. ~/.bashrc_custom' >> ~/.bashrc
