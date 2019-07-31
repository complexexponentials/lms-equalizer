import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock, Timer

@cocotb.coroutine
def reset(dut):
    dut.run <= 0
    dut.rst <= 1
    yield Timer(15, units='ns')
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)
    dut.rst._log.info("Reset complete")

@cocotb.test()
def test_counter(dut):

    cocotb.fork(Clock(dut.clk, 1, units='ns').start())
    yield reset(dut)
    
    dut.run <= 1
    yield Timer(99, units='ns')
    yield RisingEdge(dut.clk)
    dut.run <= 0
    for _ in range(10):
        yield RisingEdge(dut.clk)    

    
