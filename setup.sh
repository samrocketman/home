#!/bin/bash
#Sam Gleske home setup script
#Ubuntu 14.04 LTS \n \l
#Linux 3.13.0-24-generic x86_64
#GNU bash, version 4.3.8(1)-release (x86_64-pc-linux-gnu)

PROJECT_HOME="${PROJECT_HOME:-${HOME}/git/home}"

if [ -d "${HOME}/git/github/home" -a ! -d "${PROJECT_HOME}" ]; then
  ln -s ~/git/github/home ${PROJECT_HOME}
fi

if [ ! -d "${PROJECT_HOME}" ];then
  echo "ERR: home repo not cloned in ~/git?" >&2
  exit 1
fi

ln -s "${PROJECT_HOME}"/dotfiles/.[a-z]* ~/
if [ ! -e "${HOME}/bin" ];then
  ln -s "${PROJECT_HOME}"/bin ~/bin
fi
#configure the include file
if ! git config --global -l | grep 'include.path=~/\.gitconfig_settings' &> /dev/null; then
  echo 'Adding include.path=~/.gitconfig_settings to git settings.'
  git config --global --add include.path '~/.gitconfig_settings'
fi
#configure authordomains in git
if ! git config --global --bool authordomains.enabled &> /dev/null; then
  git config --global authordomains.enabled true
  for x in github.com gitlab.com; do
    if ! git config --global -l | grep "^authordomains.${x}" &> /dev/null; then
      echo "Setting authordomains.${x}"
      git config --global "authordomains.${x}.name" 'Sam Gleske'
      git config --global "authordomains.${x}.email" 'sam.mxracer@gmail.com'
    fi
  done
fi

grep '.bashrc_custom' ~/.bashrc &> /dev/null || echo '. ~/.bashrc_custom' >> ~/.bashrc

#Raspberry pi only setup
if grep -q 'Raspbian' /etc/issue; then
  function createservice() {
    sudo ln -s "${1}" /etc/init.d/
    sudo update-rc.d ${1##*/} defaults
    sudo /etc/init.d/${1##*/} start
  }
  echo "Setting up raspberry pi..."
  #raspbian on raspberry pi detected
  if [ ! -e "/etc/init.d/piglow-daemon.py" ]; then
    echo "Setting up piglow-daemon.py."
    #install piglow-daeomon.py prerequisites
    if [ ! -d "${HOME}/git/github/PyGlow" ]; then
      sudo apt-get install python-smbus
      (
        mkdir -p ~/git/github
        cd ~/git/github
        git clone https://github.com/benleb/PyGlow.git
        cd PyGlow
        sudo python setup.py install
      )
    fi
    createservice /home/pi/git/home/raspi/piglow-daemon.py
  fi
  if [ ! -e "/etc/init.d/force-update-date.sh" ]; then
    echo "Setting up forced NTP time sync on startup."
    createservice /home/pi/git/home/raspi/force-update-date.sh
  fi
  if [ ! -e "/etc/init.d/iptables" ]; then
    echo "Setting up iptables firewall."
    sudo ln -s /home/pi/git/home/raspi/iptables.rules /etc/
    createservice /home/pi/git/home/raspi/iptables
  fi
fi
