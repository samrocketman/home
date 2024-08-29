#!/usr/bin/python3
# Script to detect if garage door is open by IR sensors.

import RPi.GPIO as GPIO
import time
import signal
import sys

################################################################################
# Variables
################################################################################

# Frequency in Hz for how often garage door state should be checked.
automation_frequency=2

#
# pins by function
#
# Flow:
#     S1_ir -> S1_z -> G1 (garage door 1)
#     S2_ir -> S2_z -> G2 (garage door 2)
#
# reading garage door status from IR sensors
# pins: 14 (door 1 active), 18 (door 2 active), -1 (door disabled/skipped)
s1_garage_ir = 14
s2_garage_ir = -1
#s2_garage_ir = 18
# for notifying the zwave universal relay
s1_z_relay = 23
s2_z_relay = 25

################################################################################
# Functions
################################################################################

def signal_handler(sig, frame):
    GPIO.cleanup()
    print('Cleanly shut down GPIO.')
    sys.exit(0)


def set_input_pins(pins):
    for pin in pins:
        GPIO.setup(pin, GPIO.IN, GPIO.PUD_UP)

def set_output_pins(pins):
    for pin in pins:
        GPIO.setup(pin, GPIO.OUT)
        output_low(pin)

def initialize():
    # BCM mode pins 0-8 are pull-up and the rest are pull down.
    GPIO.setmode(GPIO.BCM)
    signal.signal(signal.SIGHUP, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

def activate(pin):
    GPIO.output(pin, True)

def deactivate(pin):
    GPIO.output(pin, False)

def is_beam_broken(pin):
    return GPIO.input(pin) == GPIO.LOW

################################################################################
# Main execution
################################################################################
initialize()
set_input_pins([s1_garage_ir, s2_garage_ir])
set_output_pins([s1_z_relay, s2_z_relay])
pin_pairs = [(s1_garage_ir, s1_z_relay), (s2_garage_ir, s2_z_relay)]
print('Monitoring GPIO pins.')
while True:
    for (ir_sensor, relay) in pin_pairs:
        if ir_sensor < 0:
            continue
        if is_beam_broken(ir_sensor):
            activate(relay)
        else:
            deactivate(relay)
    time.sleep(1/automation_frequency)
