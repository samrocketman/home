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
    #configure the build and install
    LDFLAGS="-lm" ./build.sh uqm config
    #build and install the game
    ./build.sh uqm install
    #start the game
    ./uqm

Now enjoy the great Star Control 2 game!  When building the game I chose the
following options:

1. Use optimized build instead of debug build.
2. Install to the prefix `/home/pi/usr` instead of `/usr/local/games`
   because I am using an alternate disk with more space mounted on `/home`.

Star Control runs best with:

* Raspberry Pi 2 or better.
* 640x480 resolution using SDL framebuffer instead of OpenGL.

### Autostart Kodi Media Center

[Kodi][kodi] (formerly XBMC) is a great way to use a Raspberry Pi.  It turns
your Pi into a complete media center PC.  I have some special enhancements made
just for Kodi.

I add [`delay-start-kodi.sh`](delay-start-kodi.sh) to `.bashrc`.  This script
will automatically start kodi after 5 seconds.  However, in order for the script
to work you must:

* Use `raspi-config` to disable booting to GUI (I recommend autologin).

This script depends on building the [`getkey` command](src/getkey.c) because
you're able to stop kodi from starting by holding the SHIFT key.  If you're
using [`setup.sh`](setup.sh) then it should set up your `.bashrc` as well as
build `getkey`.

Kodi is best run without the GUI so that you can dedicate maximum resources to
Kodi and video decoding rather than taking up memory with a GUI.

# My favorite Pi programs

Besides my normal favorites such as `vim` I like keeping a list of very
lightweight programs to use.

* `mirage` - A simple graphics editor and viewer that is less than 100Kb.

[kodi]: https://kodi.tv/
[piglow-tute]: http://www.raspberrypi.org/learning/piglow
[piglow]: http://shop.pimoroni.com/products/piglow
[piglowd]: https://github.com/lawrie/piglowd
[raspi]: http://www.raspberrypi.org/
