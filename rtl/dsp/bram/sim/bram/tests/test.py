import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock, Timer

@cocotb.coroutine
def reset(dut):
    dut.log_in_ram_run_from_micro <= 0
    dut.soft_reset <= 1
    dut.rf_enables_module <= 0
    dut.log_read_addr_from_micro <= 0
    dut.log_in_1 <= 0
    dut.log_in_2 <= 0
    dut.log_in_3 <= 0

    
    yield Timer(15, units='ns')
    yield RisingEdge(dut.clockdsp)
    dut.soft_reset <= 0
    yield RisingEdge(dut.clockdsp)
    dut.soft_reset._log.info("Reset complete")

@cocotb.test()
def test_counter(dut):

    cocotb.fork(Clock(dut.clockdsp, 1, units='ns').start())
    yield reset(dut)
    
    dut.log_in_ram_run_from_micro <= 1
    yield RisingEdge(dut.log_out_full_from_ram)
    dut.log_in_ram_run_from_micro <= 0

    
    yield Timer(10, units='ns')

    read_values = []
    
    for address in range(2**15):
        dut.log_read_addr_from_micro <= address
        yield RisingEdge(dut.clockdsp)
        read_values.append(dut.log_read_addr_from_micro.value.integer)
    
    # test read_values
    yield Timer(10, units='ns')

    values = list(range(2**15))
    
    if values != read_values:
        print(read_values)
        raise TestFailure("Los valores no coinciden")
            
