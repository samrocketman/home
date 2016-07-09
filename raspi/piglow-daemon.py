#!/usr/bin/env python
#Created by Sam Gleske
#Sat Mar 21 17:34:40 EDT 2015
#Raspbian GNU/Linux 7
#Linux 3.18.7-v7+ armv7l
#Python 2.7.3

#DESCRIPTION
#  My pulsing piglow daemon.

### BEGIN INIT INFO
# Provides:          piglow-daemon.py
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: PiGlow daemon startup
# Description:      Daemon to contol a Piglow board
### END INIT INFO

from PyGlow import PyGlow, ARM_LED_LIST, BOTH
from time import sleep
import atexit
import os
import signal
import sys
import time

#reset the colors to zero brightness
piglow = PyGlow()
piglow.all(0)

#
#
# PIGLOW LEDS
#
#

#max brightness when pulsing (0-255)
PULSE_BRIGHTNESS = 200

#ALL LEDS
#LED list is 1-18
LED_LIST = range(1,19)

#LED INDEXES GROUPED BY LED WINGS
#first wing (1 of 3 wings), LEDs 1-6
FAN1 = range(1,7)
#second wing (2 of 3 wings), LEDs 13-18
FAN2 = range(13,19)
#third wing (3 of 3 wings), LEDs 7-12
FAN3 = range(7,13)

#LED INDEXES GROUPED BY COLOR
RED = [1, 7, 13]
ORANGE = [2, 8, 14]
YELLOW = [3, 9, 15]
GREEN = [4, 10, 16]
BLUE = [5, 11, 17]
WHITE = [6, 12, 18]

#
#
# FUNCTIONS
#
#

#functions
def slow_pulse_piglow(color):
    piglow = PyGlow(brightness=PULSE_BRIGHTNESS, pulse=True, speed=5000, pulse_dir=BOTH)
    piglow.set_leds(color).update_leds()

def spaz():
    piglow = PyGlow()
    for x in range(1,19)+range(18,0,-1):
        piglow.set_leds([x], PULSE_BRIGHTNESS).update_leds()
        sleep(0.01)
        piglow.set_leds([x], 0).update_leds()
        sleep(0.05)

#
#
# DAEMON CLASSES
#
#

#http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/
class Daemon:
    """
    A generic daemon class.

    Usage: subclass the Daemon class and override the run() method
    """
    def __init__(self, pidfile, stdin='/dev/null', stdout='/dev/null', stderr='/dev/null'):
        self.stdin = stdin
        self.stdout = stdout
        self.stderr = stderr
        self.pidfile = pidfile

    def daemonize(self):
        """
        do the UNIX double-fork magic, see Stevens' "Advanced
        Programming in the UNIX Environment" for details (ISBN 0201563177)
        http://www.erlenstar.demon.co.uk/unix/faq_2.html#SEC16
        """
        try:
            pid = os.fork()
            if pid > 0:
                # exit first parent
                sys.exit(0)
        except OSError, e:
            sys.stderr.write("fork #1 failed: %d (%s)\n" % (e.errno, e.strerror))
            sys.exit(1)

        # decouple from parent environment
        os.chdir("/")
        os.setsid()
        os.umask(0)

        # do second fork
        try:
            pid = os.fork()
            if pid > 0:
                # exit from second parent
                sys.exit(0)
        except OSError, e:
            sys.stderr.write("fork #2 failed: %d (%s)\n" % (e.errno, e.strerror))
            sys.exit(1)

        # redirect standard file descriptors
        sys.stdout.flush()
        sys.stderr.flush()
        si = file(self.stdin, 'r')
        so = file(self.stdout, 'a+')
        se = file(self.stderr, 'a+', 0)
        os.dup2(si.fileno(), sys.stdin.fileno())
        os.dup2(so.fileno(), sys.stdout.fileno())
        os.dup2(se.fileno(), sys.stderr.fileno())

        # write pidfile
        atexit.register(self.delpid)
        pid = str(os.getpid())
        file(self.pidfile,'w+').write("%s\n" % pid)

    def delpid(self):
        os.remove(self.pidfile)

    def start(self):
        """
        Start the daemon
        """
        # Check for a pidfile to see if the daemon already runs
        try:
            pf = file(self.pidfile,'r')
            pid = int(pf.read().strip())
            pf.close()
        except IOError:
            pid = None

        if pid:
            message = "pidfile %s already exist. Daemon already running?\n"
            sys.stderr.write(message % self.pidfile)
            sys.exit(1)

        # Start the daemon
        self.daemonize()
        self.run()

    def stop(self):
        """
        Stop the daemon
        """
        # Get the pid from the pidfile
        try:
            pf = file(self.pidfile,'r')
            pid = int(pf.read().strip())
            pf.close()
        except IOError:
            pid = None

        if not pid:
            message = "pidfile %s does not exist. Daemon not running?\n"
            sys.stderr.write(message % self.pidfile)
            return # not an error in a restart

        # Try killing the daemon process
        try:
            while 1:
                os.kill(pid, signal.SIGTERM)
                time.sleep(0.1)
        except OSError, err:
            err = str(err)
            if err.find("No such process") > 0:
                if os.path.exists(self.pidfile):
                    os.remove(self.pidfile)
            else:
                print str(err)
                sys.exit(1)

    def restart(self):
        """
        Restart the daemon
        """
        self.stop()
        self.start()

    def run(self):
        """
        You should override this method when you subclass Daemon. It will be called after the process has been
        daemonized by start() or restart().
        """

#my daemon class
class MyDaemon(Daemon):
    def handler(self, signum = None, frame = None):
        """
        A signal handler for the daemon.
        """
        self.delpid()
        #turn off the leds during process kill
        piglow.all(0)
        sys.exit(0)
    def run(self):
        for sig in [signal.SIGTERM, signal.SIGINT, signal.SIGHUP, signal.SIGQUIT]:
            signal.signal(sig, self.handler)
        #wake up to a spaz of colors!
        spaz()
        #piglow daemonized loop
        while True:
            #cycle through the colors with a slow pulse
            map(slow_pulse_piglow, [RED, ORANGE, YELLOW, GREEN, BLUE, WHITE])

#
#
# MAIN RUNTIME
#
#

#main function
if __name__ == "__main__":
    daemon = MyDaemon('/var/run/piglow-daemon.pid')
    if len(sys.argv) == 2:
        if 'start' == sys.argv[1]:
            daemon.start()
        elif 'stop' == sys.argv[1]:
            daemon.stop()
        elif 'restart' == sys.argv[1]:
            daemon.restart()
        else:
            print "Unknown command"
            sys.exit(2)
        sys.exit(0)
    else:
        print "usage: %s start|stop|restart" % sys.argv[0]
        sys.exit(2)
