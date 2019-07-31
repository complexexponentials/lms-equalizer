#!/usr/bin/python3

import cocotb
import numpy as np
import matplotlib.pyplot as plt
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock, Timer

@cocotb.coroutine
def reset(dut):
    dut.rst <= 1
    dut.en  <= 0
    dut.din <= 0
    
    dut.coef0 <= 0
    dut.coef1 <= 0
    dut.coef2 <= 0
    dut.coef3 <= 128
    dut.coef4 <= 0
    dut.coef5 <= 0
    dut.coef6 <= 0
    
    yield Timer(15, units='ns')
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)
    dut.rst._log.info("Reset complete")

@cocotb.test()
def test_ffe(dut):

    cocotb.fork(Clock(dut.clk, 1, units='ns').start())
    yield reset(dut)
    
    dut.en  <= 1

    yield Timer(10, units='ns')
    
    
    fir_output = np.zeros(100, dtype=int)
    
    fir_input_prbs = np.random.choice([128, 1920], (100))
    fir_input_pulse = np.concatenate((np.ones(50)*128, np.ones(50)*-128))
    for i,val in enumerate(fir_input_prbs.astype('int')):
        dut.din <= val
        yield RisingEdge(dut.clk)
        fir_output[i] = dut.dout.value.signed_integer
    
    # test read_values
    yield Timer(10, units='ns')

    plt.figure()
    plt.plot(np.where(fir_input_prbs == 128, 128, -128))
    plt.plot(fir_output)
    plt.show(block=True)
    #_ = input('Presione enter para terminar')
    plt.close()
