#!/usr/bin/python3
# Script to detect if garage door is open by IR sensors.  If the door is open,
# then it triggers a relay for an external notification system like Zooz
# universal relay for garage doors.

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
#     S1_ir -> R1_z -> G1 (garage door 1)
#     S2_ir -> R2_z -> G2 (garage door 2)
#
# reading garage door status from IR sensors
# pins: 14 (door 1 active), 18 (door 2 active), -1 (door disabled/skipped)
s1_garage_ir = 14
s2_garage_ir = -1
#s2_garage_ir = 18
# for notifying the zwave universal relay
r1_z_relay = 23
r2_z_relay = 25

################################################################################
# Functions
################################################################################

def signal_handler(sig, frame):
    """
    Handles graceful shutdown of GPIO when the daemon is stopped.
    """
    GPIO.cleanup()
    print('Cleanly shut down GPIO.')
    sys.exit(0)


def set_input_pins(pins):
    """
    IR sensors require pull-up resistors which are built-in for the Raspberry
    Pi Zero 2W.
    """
    for pin in pins:
        if pin < 0:
            continue
        GPIO.setup(channel=pin, direction=GPIO.IN, pull_up_down=GPIO.PUD_UP)

def set_output_pins(pins):
    """
    Prepare pins for 3.3v output for triggering 12v relays.
    """
    for pin in pins:
        GPIO.setup(channel=pin, direction=GPIO.OUT, initial=GPIO.LOW)

def initialize():
    """
    Prepares GPIO for work and graceful shutdown of GPIO program termination.
    """
    # BCM mode pins 0-8 are pull-up and the rest are pull down.
    GPIO.setmode(GPIO.BCM)
    signal.signal(signal.SIGHUP, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

def activate(pin):
    """
    Sends high output (3.3v) to GPIO pin.
    """
    GPIO.output(pin, True)

def deactivate(pin):
    """
    Sends low output (~0v) to GPIO pin.
    """
    GPIO.output(pin, False)

def is_beam_broken_for(ir_sensor_pin):
    """
    Assumes a digital break-beam IR sensor is plugged into the pin.  If the pin
    reads high, then the IR beam is intact.  If the pin reads low, then the IR
    beam is broken.

    Garage door open == broken beam and garage door closed == intact beam.

    Function returns True if beam is broken i.e. garage door open.
    """
    return GPIO.input(ir_sensor_pin) == GPIO.LOW

################################################################################
# Main execution
################################################################################
initialize()
set_input_pins([s1_garage_ir, s2_garage_ir])
set_output_pins([r1_z_relay, r2_z_relay])
pin_pairs = [(s1_garage_ir, r1_z_relay), (s2_garage_ir, r2_z_relay)]
print('Monitoring GPIO pins.')
while True:
    for (ir_sensor, relay) in pin_pairs:
        if ir_sensor < 0:
            continue
        if is_beam_broken_for(ir_sensor):
            activate(relay)
        else:
            deactivate(relay)
    time.sleep(1/automation_frequency)
