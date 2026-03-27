#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
A test bench depicting a primitive motor model

The goal of this test bench isn't to be physically precise, but rather
to provide a plausible sink for a PWM signal - which should plausibly
affect the inner motor model, and a plausible source for a rotary
encoder signal - which depends on the simulated motor speed.

The secondary goal is to demonstrate that I don't entirely suck at VHDL...
I just suck at synthesizing things...
"""

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock

# Clock properties
TIME_UNIT = "ns"
CLOCK_PERIOD = 10

# Time-stamp limit (in cycles)
TS_LIMIT = 250_000

# Motor physical parameters
DRAG_COEFF = 0.001
PULSE_ENERGY = 0.002

# Rotary encoder parameters
MAX_ENCODER_INTERVAL = 100
TARGET_ENCODER_INTERVAL = 10
MIN_ENCODER_INTERVAL = 4
MIN_MOTOR_SPEED = 0.01

# Global state variables
motor_speed = 0
ts_ctr = 0


async def doc_state(dut):
    """Document current state"""
    global TS_LIMIT, motor_speed, ts_ctr

    f = open("motor_model_state.csv", "w+")
    f.write("'index','cycle','dir','en','velocity','motor_speed'\n")

    inner_ctr = 0
    while ts_ctr < TS_LIMIT:
        v_dir, v_en, v_velocity = 0, 0, 0

        try:
            v_dir, v_en, v_velocity = (
                int(dut.dir.value),
                int(dut.en.value),
                int(dut.v_bus.value),
            )
        except:
            pass

        f.write(
            "%d,%d,%d,%d,%d,%.6f\n"
            % (inner_ctr, ts_ctr, v_dir, v_en, v_velocity, motor_speed)
        )

        await RisingEdge(dut.clk)
        inner_ctr += 1

    f.sync()
    f.close()


async def motor_model(dut):
    """Implement a motor model"""
    global TS_LIMIT, motor_speed
    has_warned = False

    while ts_ctr < TS_LIMIT:
        # Trigger at master clock edge
        await RisingEdge(dut.clk)

        if dut.done.value != 0 and not has_warned:
            dut._log.warning("self-test unit has finished issuing sequences")
            has_warned = True

        # Obtain values for `dir` and `en`, then use it to calculate motor speed
        pulse = PULSE_ENERGY if dut.dir.value == 1 else -PULSE_ENERGY
        is_high = 1 if dut.en.value != 0 else 0
        motor_speed = (1 - DRAG_COEFF) * motor_speed + is_high * pulse


async def speed_sensor(dut):
    """Implement a rotary encoder model"""
    global motor_speed, ts_ctr
    next_int = 0

    while ts_ctr < TS_LIMIT:
        # Calculate delay between pulses based on current motor speed
        this_motor_speed = float(motor_speed)
        delay = MAX_ENCODER_INTERVAL

        if abs(this_motor_speed) > MIN_MOTOR_SPEED:
            delay = int(
                max(
                    MIN_ENCODER_INTERVAL,
                    min(delay, TARGET_ENCODER_INTERVAL / abs(this_motor_speed)),
                )
            )

        # Calculate current Gray code, then
        # write it to port `ab`
        gray = next_int ^ (next_int >> 1)
        gray &= 3

        dut.ab.value = gray

        # Wait this many cycles
        for _ in range(delay):
            await RisingEdge(dut.clk)

        ts_ctr += delay

        # Calculate next index based on recently observed motor speed
        # - no_op if absolute motor speed is below minimum motor speed
        this_motor_speed = float(motor_speed)

        if this_motor_speed >= MIN_MOTOR_SPEED:
            next_int = (4 + next_int + 1) % 4
        elif this_motor_speed <= -MIN_MOTOR_SPEED:
            next_int = (4 + next_int - 1) % 4


@cocotb.test()
async def main_test(dut):
    """Try accessing the design."""

    dut._log.info("Running test...")

    # Assert reset
    dut.ab.value = 0
    dut.reset.value = 1

    # Start clock
    dut._log.info("Starting clock with period %d %s..." % (CLOCK_PERIOD, TIME_UNIT))
    cocotb.start_soon(Clock(dut.clk, CLOCK_PERIOD, unit=TIME_UNIT).start())

    # Hold reset for two cycles, then de-assert it
    await Timer(2 * CLOCK_PERIOD, unit=TIME_UNIT)
    dut.reset.value = 0

    await RisingEdge(dut.clk)

    dut._log.info("Starting data logger...")
    cocotb.start_soon(doc_state(dut))

    dut._log.info("Starting motor model...")
    cocotb.start_soon(motor_model(dut))

    dut._log.info("Starting speed sensor...")
    await cocotb.start_soon(speed_sensor(dut))

    dut._log.info("Running test...done")
