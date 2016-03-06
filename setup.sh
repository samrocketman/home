#!/bin/bash
#Sam Gleske home setup script
#Ubuntu 14.04 LTS \n \l
#Linux 3.13.0-24-generic x86_64
#GNU bash, version 4.3.8(1)-release (x86_64-pc-linux-gnu)

#
# HOME REPOSITORY CONFIGURATION AND SAFETY CHECKS
#
PROJECT_HOME="${PROJECT_HOME:-${HOME}/git/home}"

if [ -d "${HOME}/git/github/home" -a ! -d "${PROJECT_HOME}" ]; then
  ln -s ~/git/github/home ${PROJECT_HOME}
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
#configure authordomains in git
if ! git config --global --bool authordomains.enabled &> /dev/null; then
  echo 'Enable authordomains.'
  git config --global authordomains.enabled true
  for x in github.com gitlab.com git.gnome.org; do
    if ! git config --global -l | grep "^authordomains.${x}" &> /dev/null; then
      echo "Setting authordomains.${x}"
      git config --global "authordomains.${x}.name" 'Sam Gleske'
      git config --global "authordomains.${x}.email" 'sam.mxracer@gmail.com'
    fi
  done
fi
#copy pre-commit hook into existing git repositories.
if [ -e "${HOME}/git" ]; then
  (
    cd "${HOME}/git"
    find . -type d -name '.git' | while read x;do
      if [ ! -e "${x}/hooks/pre-commit" ]; then
        cp "${HOME}/.git_template/hooks/pre-commit" "${x}/hooks/"
      fi
    done
  )
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
