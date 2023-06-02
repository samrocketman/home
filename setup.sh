#!/bin/bash
#Sam Gleske home setup script
#Ubuntu 14.04 LTS \n \l
#Linux 3.13.0-24-generic x86_64
#GNU bash, version 4.3.8(1)-release (x86_64-pc-linux-gnu)

#
# HOME REPOSITORY CONFIGURATION AND SAFETY CHECKS
#
PROJECT_HOME="${PROJECT_HOME:-${HOME}/git/home}"

if [ -d "${PROJECT_HOME}" -a ! -d "${HOME}/git/github/home" ]; then
  mkdir -p "${HOME}/git/github"
  ln -s ${PROJECT_HOME} ~/git/github/
fi

if [ ! -d "${PROJECT_HOME}" ];then
  echo "ERR: home repo not cloned in ~/git?" >&2
  exit 1
fi

#
# USE MY DOTFILES
#
#link all dotfiles to $HOME directory
ln -s "${PROJECT_HOME}"/dotfiles/.[a-z]* ~
mkdir -p ~/.vim/autoload ~/.vim/bundle
#if login shell then use .bash_profile
if shopt -q login_shell;then
  #yes it is a login shell
  grep '\.bashrc_custom' ~/.bash_profile &> /dev/null || echo '. ~/.bashrc_custom' >> ~/.bash_profile
else
  #it is not a Mac
  grep '\.bashrc_custom' ~/.bashrc &> /dev/null || echo '. ~/.bashrc_custom' >> ~/.bashrc
fi

#
# CONFIGURE GLOBAL GIT SETTINGS
#
#set default user
if ! git config --global -l 2> /dev/null | grep 'user\.email=sam\.mxracer' &> /dev/null; then
  echo 'Setting global author to sam.mxracer email.'
  git config --global user.name 'Sam Gleske'
  git config --global user.email 'sam.mxracer@gmail.com'
fi
#configure the include file
if ! git config --global -l | grep 'include.path=~/\.gitconfig_settings' &> /dev/null; then
  echo 'Adding include.path=~/.gitconfig_settings to git settings.'
  git config --global --add include.path '~/.gitconfig_settings'
fi

if [ ! -e "$HOME/bin" ]; then
  ln -s "$HOME/git/home/bin" "$HOME/bin"
fi

#
# RASPBERRY PI ONLY SETUP
#
if (uname -rms | grep -v 'Darwin' &> /dev/null) && grep -q 'Raspbian' /etc/issue; then
  ./raspi/setup.sh
fi

#
# Download preferred utilities
#
mkdir -p ~/usr/bin ~/usr/src ~/usr/share
./misc/install-utilities.sh
