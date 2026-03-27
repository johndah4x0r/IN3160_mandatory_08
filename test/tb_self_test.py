#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock

TIME_UNIT = "us"
CLOCK_PERIOD = 10


@cocotb.test()
async def main_test(dut):
    """Try accessing the design."""

    dut._log.info("Running test...")

    # Assert reset
    dut.reset.value = 1

    # Start clock
    dut._log.info("Starting clock with period %d %s..." % (CLOCK_PERIOD, TIME_UNIT))
    cocotb.start_soon(Clock(dut.clk, CLOCK_PERIOD, unit=TIME_UNIT).start())

    # Hold reset for two cycles, then de-assert it
    await Timer(2 * CLOCK_PERIOD, unit=TIME_UNIT)
    dut.reset.value = 0

    # Wait...
    dut._log.info("Applying stored sequence...")
    while dut.done.value != 1:
        await RisingEdge(dut.clk)

    dut._log.info("Running test...done")
