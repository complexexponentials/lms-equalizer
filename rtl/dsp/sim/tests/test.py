#!/usr/bin/python3

import cocotb
import numpy as np
import matplotlib.pyplot as plt
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock, Timer

channel   = [[0,0,0,0.9921875,0,0,0],
             [0,0,0.2421875,0.96875,0,0,0],
             [0,0,0.2421875,0.96875,0.09375,0,0],
             [0,0.171875,0.4375,0.875,0.0859375,0,0]]
ch_sel = 1

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

    N = 1000
    dut.rf_enables_module <= 1
    fir_output = np.zeros(N, dtype=int)
    err_output = np.zeros(N, dtype=int)
    coefs_out  = np.zeros((N,7), dtype=int)
    
    fir_input_prbs = np.convolve(np.random.choice([128, -128], (N)), channel[ch_sel], mode='same')
    fir_input_pulse = np.concatenate((np.ones(50)*128, np.ones(50)*-128))
    for i,val in enumerate(fir_input_prbs.astype('int')):
        dut.connect_ch_to_dsp <= val
        yield RisingEdge(dut.clockdsp)
        fir_output[i] = dut.ffe_inst.o_data.value.signed_integer
        err_output[i] = dut.error.value.signed_integer
        for k in range(7):
            coefs_out[i,k] = dut.ffe_inst.coefs[k].value.signed_integer

    # test read_values
    yield Timer(10, units='ns')

    plt.figure()
    plt.plot(np.where(fir_input_prbs == 128, 128, -128))
    plt.plot(fir_output)
    plt.figure()
    plt.plot(err_output)

    plt.figure()
    plt.subplot(2,1,1)
    plt.stem(fir_output[0:200])
    plt.grid()
    plt.ylim((np.min(fir_output)-0.5,np.max(fir_output)+0.5))
    plt.ylabel('Amplitude')
    plt.xlabel('Samples')
    plt.title('FFE Output and Error - HW')
    plt.subplot(2,1,2)
    plt.plot(err_output)
    plt.grid()
    plt.ylim((np.min(err_output)-0.5,np.max(err_output)+0.5))
    plt.ylabel('Amplitude')
    plt.xlabel('Samples')

    plt.figure()
    plt.subplot(3,1,1)
    plt.plot(coefs_out)
    plt.grid()
    plt.ylim((min(coefs_out[len(coefs_out)-1])-12,max(coefs_out[len(coefs_out)-1])+12))
    plt.ylabel('Amplitude')
    plt.title('Taps of FFE')
    plt.subplot(3,1,2)
    plt.stem(coefs_out[len(coefs_out)-1])
    plt.grid()
    plt.ylim((min(coefs_out[len(coefs_out)-1])-0.5,max(coefs_out[len(coefs_out)-1])+0.5))
    plt.ylabel('Amplitude')
    plt.subplot(3,1,3)
    plt.stem(np.convolve(channel[ch_sel],coefs_out[len(coefs_out)-1]))
    plt.grid()
    plt.ylim((min(coefs_out[len(coefs_out)-1])-0.5,max(coefs_out[len(coefs_out)-1])+0.5))
    plt.ylabel('Conv.Ch.Taps')
    plt.xlabel('Samples')

    plt.show(block=True)

    plt.close()
