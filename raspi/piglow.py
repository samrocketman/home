#!/usr/bin/python
#Created by Sam Gleske
#Sat Mar 21 17:34:46 EDT 2015
#Raspbian GNU/Linux 7 \n \l
#Linux 3.18.7-v7+ armv7l
#Python 2.7.3

#DESCRIPTION
#  My blinging piglow setup which autostarts on startup.

from PyGlow import PyGlow, ARM_LED_LIST, BOTH
from time import sleep

#max brightness when pulsing
PULSE_BRIGHTNESS = 255

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

#reset the colors to zero brightness
piglow = PyGlow()
piglow.all(0)

#functions
def slow_pulse_piglow(color):
    piglow = PyGlow(brightness=PULSE_BRIGHTNESS, pulse=True, speed=5000, pulse_dir=BOTH)
    piglow.set_leds(color).update_leds()

try:
    while True:
        #cycle through the colors with a slow pulse
        map(slow_pulse_piglow, [RED, ORANGE, YELLOW, GREEN, BLUE, WHITE])
except:
    piglow.all(0)
