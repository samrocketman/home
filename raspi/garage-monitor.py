#!/usr/bin/python3
# Proof of concept for Garage door detection.

import RPi.GPIO as GPIO
import time
import signal
import sys
#import time.sleep as sleep

# Frequency in Hz for how often garage door state should be checked.
automation_frequency=2

def signal_handler(sig, frame):
    GPIO.cleanup()
    print('Cleanly shut down GPIO.')
    sys.exit(0)


def set_input_pins(pins):
    for pin in pins:
        GPIO.setup(pin,GPIO.IN)

def set_output_pins(pins):
    for pin in pins:
        GPIO.setup(pin,GPIO.OUT)
        output_low(pin)

def initialize():
    # BCM mode pins 0-8 are pull-up and the rest are pull down.
    GPIO.setmode(GPIO.BCM)
    signal.signal(signal.SIGHUP, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

def output_high(pin):
    GPIO.output(pin, True)

def output_low(pin):
    GPIO.output(pin, False)

count=0

# garage doors 1 and 2
#g1_door_open_sensor=
#g2_door_open_sensor=
notify_zwave_g1_open_relay=23
#g2_open_zwave_relay=23

initialize()
set_output_pins([notify_zwave_g1_open_relay])
count=0
while True:
    if count & 1 == 0:
        output_high(notify_zwave_g1_open_relay)
    else:
        output_low(notify_zwave_g1_open_relay)
    count+=1
    time.sleep(automation_frequency/2)
