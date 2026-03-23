#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock

TIME_UNIT = "ns"
CLOCK_PERIOD = 10


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

    # - wait another cycle
    await RisingEdge(dut.clk)

    # Apply forward and reverse sequences, with
    # illegal transitions at the end
    # - note that the values are Gray-encoded
    seq_forward = [0, 1, 3, 2, 0, 1, 3, 0, 1]
    seq_reverse = [2, 3, 1, 0, 2, 3, 1, 2, 3]

    for i in seq_forward:
        # - apply sequence to `ab`
        dut.ab.value = i

        # - wait 4 cycles
        await Timer(4 * CLOCK_PERIOD, unit=TIME_UNIT)

    # - reset `ab`
    dut.ab.value = 0
    await Timer(4 * CLOCK_PERIOD, unit=TIME_UNIT)

    for i in seq_reverse:
        # - apply sequence to `ab`
        dut.ab.value = i

        # - wait 4 cycles
        await Timer(4 * CLOCK_PERIOD, unit=TIME_UNIT)

    dut._log.info("Running test...done")
