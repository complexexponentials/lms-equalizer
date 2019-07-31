#!/usr/bin/python3

import cocotb
import numpy as np
import matplotlib.pyplot as plt
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock, Timer

@cocotb.coroutine
def reset(dut):
    dut.soft_reset <= 1
    dut.step_mu  <= 0
    dut.connect_ch_to_dsp <= 0
    dut.rf_enables_module <= 0
    dut.log_in_ram_run_from_micro <= 0
    dut.log_read_addr_from_micro <= 0
    
    yield Timer(15, units='ns')
    yield RisingEdge(dut.clockdsp)
    dut.soft_reset <= 0
    yield RisingEdge(dut.clockdsp)
    dut.soft_reset._log.info("Reset complete")

@cocotb.test()
def test_dsp(dut):

    cocotb.fork(Clock(dut.clockdsp, 1, units='ns').start())
    yield reset(dut)
    

    yield Timer(10, units='ns')
    dut.step_mu <= 4 # 0,1,4,16

    N = 10000
    dut.rf_enables_module <= 1
    fir_output = np.zeros(N, dtype=int)
    err_output = np.zeros(N, dtype=int)
    
    fir_input_prbs = np.random.choice([128, 1920], (N))
    fir_input_pulse = np.concatenate((np.ones(50)*128, np.ones(50)*-128))
    for i,val in enumerate(fir_input_prbs.astype('int')):
        dut.connect_ch_to_dsp <= val
        yield RisingEdge(dut.clockdsp)
        fir_output[i] = dut.ffe_inst.o_data.value.signed_integer
        err_output[i] = dut.error.value.signed_integer
    
    # test read_values
    yield Timer(10, units='ns')

    plt.figure()
    plt.plot(np.where(fir_input_prbs == 128, 128, -128))
    plt.plot(fir_output)
    plt.figure()
    plt.plot(err_output)
    plt.show(block=True)
    plt.close()
