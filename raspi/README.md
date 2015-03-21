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

# force-update-date.sh

Raspbian does a pretty poor job at time synchronization at startup.  It does the
best it can however it leaves much to be desired.  I wrote this script to force
update the date and time with `us.pool.ntp.org`.

### Autostart time sync on boot

Add daemon to system.

    sudo ln -s /home/pi/git/home/raspi/force-update-date.sh /etc/init.d/

Generate appropriate startup and shutdown links.

    sudo update-rc.d force-update-date.sh start

[piglowd]: https://github.com/lawrie/piglowd
[piglow]: http://shop.pimoroni.com/products/piglow
[piglow-tute]: http://www.raspberrypi.org/learning/piglow
[raspi]: http://www.raspberrypi.org/
