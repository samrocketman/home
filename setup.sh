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

grep '.bashrc_custom' ~/.bashrc &> /dev/null || echo '. ~/.bashrc_custom' >> ~/.bashrc

if grep -q 'Raspbian' /etc/issue; then
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
    sudo ln -s /home/pi/git/home/raspi/piglow-daemon.py /etc/init.d/
    sudo update-rc.d piglow-daemon.py start
  fi
  if [ ! -e "/etc/init.d/force-update-date.sh" ]; then
    sudo ln -s /home/pi/git/home/raspi/force-update-date.sh /etc/init.d/
    sudo update-rc.d force-update-date.sh start
  fi
fi
