# Raspberry PI scripts

These are different things I've developed playing with my [raspberry pi][raspi].
I bought a [piglow][piglow] and [learned how to use it with a
library][piglow-tute].

# piglow-daemon.py

This script is a simple daemon that starts up when my raspberry pi boots.  It is
a low distraction pulse.  I wrote this before I found [piglowd][piglowd].  I'll
have to check out piglowd and see if I can get that working as well.

### Prerequisites

Ensure that `/etc/modules` contains the following two lines.

    i2c-dev
    snd-bcm2835

Ensure that none of those modules is in `/etc/modprobe.d/raspi-blacklist.conf`.
If they are then comment them out.  Install required system packages.

    sudo apt-get install python-smbus

Install the PyGlow python library into the system.

    git clone https://github.com/benleb/PyGlow.git
    cd PyGlow
    sudo python setup.py install

### Autostart the daemon on boot

Add daemon to system.

    sudo ln -s /home/pi/git/home/raspi/piglow-daemon.py /etc/init.d/

Generate appropriate startup and shutdown links.

    sudo update-rc.d piglow-daemon.py start

### force-update-date.sh

Raspbian does a pretty poor job at time synchronization at startup.  It does the
best it can however it leaves much to be desired.  I wrote this script to force
update the date and time with `us.pool.ntp.org`.

### Autostart time sync on boot

Add daemon to system.

    sudo ln -s /home/pi/git/home/raspi/force-update-date.sh /etc/init.d/

Generate appropriate startup and shutdown links.

    sudo update-rc.d force-update-date.sh start

### Build Star Control 2

These instructions outline how to build the game Star Control 2 on a raspberry
pi running Raspian.

    #clone
    cd ~/git
    git clone http://git.code.sf.net/p/sc2/uqm sc2-uqm
    cd sc2-uqm/sc2/
    #install dependencies
    sudo apt-get install -y gcc libsdl1.2-dev libsdl-image1.2-dev libogg-dev libvorbis-dev zlib1g-dev libmikmod-dev mikmod
    #build and install the game
    LDFLAGS="-lm" ./build.sh uqm install

Now enjoy the great Star Control 2 game!  When building the game I chose the
following options:

1. Use optimized build instead of debug build.
2. Install to the prefix `/home/pi/usr/games` instead of `/usr/local/games`
   because I am using an alternate disk with more space mounted on `/home`.

[piglow-tute]: http://www.raspberrypi.org/learning/piglow
[piglow]: http://shop.pimoroni.com/products/piglow
[piglowd]: https://github.com/lawrie/piglowd
[raspi]: http://www.raspberrypi.org/
