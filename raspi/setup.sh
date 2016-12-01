#!/bin/bash
#
# RASPBERRY PI ONLY SETUP
#

#detect retropi
isRetroPi=false
if type -p emulationstation &> /dev/null; then
  isRetroPi=true
fi

function createservice() {
  sudo ln -s "${1}" /etc/init.d/
  sudo update-rc.d ${1##*/} defaults
  sudo /etc/init.d/${1##*/} start
}
echo "Setting up raspberry pi..."
sudo apt-get update
sudo apt-get upgrade -y
#raspbian on raspberry pi detected
if [ ! -e "/etc/init.d/piglow-daemon.py" ]; then
  echo "Setting up piglow-daemon.py."
  #install piglow-daeomon.py prerequisites
  if [ ! -d "${HOME}/git/github/PyGlow" ]; then
    sudo apt-get install -y python-smbus python-setuptools
    (
      mkdir -p ~/git/github
      cd ~/git/github
      git clone https://github.com/benleb/PyGlow.git
      cd PyGlow
      sudo python setup.py install
    )
  fi
  createservice /home/pi/git/home/raspi/piglow-daemon.py
  #load kernel modules on boot
  if ! grep i2c-dev /etc/modules; then
    sudo su - -c "echo 'i2c-dev' >> /etc/modules"
  fi
  if ! grep snd-bcm2835 /etc/modules; then
    sudo su - -c "echo 'snd-bcm2835' >> /etc/modules"
  fi
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

#additional packages
sudo apt-get install -y vim screen irssi ntpdate kodi

#remove space hog packages
sudo apt-get remove -y wolfram-engine minecraft-pi

#set the hostname to funberry!
sudo "$HOME/bin/update_hostname.sh" funberry

#setup kodi
#setup getkey binary
if [ ! -f "${HOME}/usr/bin/getkey" ]; then
  mkdir -p ~/usr/bin
  gcc -o ~/usr/bin/getkey ~/git/home/raspi/src/getkey.c
fi
if ! ${isRetroPi}; then
  grep 'delay-start-kodi\.sh' ~/.bashrc &> /dev/null || echo "${HOME}/git/home/raspi/delay-start-kodi.sh" >> ~/.bashrc
fi
if ! groups pi | grep tty &> /dev/null; then
  sudo usermod -a -G tty pi
fi
if ! ${isRetroPi}; then
  if grep gpu_mem /boot/config.txt; then
    echo 'gpu_mem=256' >> /boot/config.txt
  else
    sed -i 's/^\(gpu_mem\)=[0-9]\+/\1=256' /boot/config.txt
  fi
fi
#if additional problems are encountered with kodi... check out:
#https://www.raspberrypi.org/forums/viewtopic.php?t=99866
