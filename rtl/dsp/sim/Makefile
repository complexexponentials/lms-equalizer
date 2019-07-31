
export COCOTB_REDUCED_LOG_FMT
export PYTHONPATH:=$(realpath tests):$(PYTHONPATH)

LANG=verilog
SIM=icarus

SPATH = $(PWD)/..
VERILOG_SOURCES= $(SPATH)/dsp.v \
                 $(SPATH)/ffe/ffe.v \
                 $(SPATH)/ffe/ffe_dir.v \
                 $(SPATH)/lms/lms.v \
                 $(SPATH)/bram/bram.v \
                 $(SPATH)/bram/log_fsm.v \
                 $(SPATH)/bram/mod_m_counter.v \
                 $(SPATH)/bram/dual_port_ram.v

COMPILE_ARGS = -Wall

TOPLEVEL=dsp

MODULE ?= test

COCOTB=$(shell cocotb-config --makefiles)
include $(COCOTB)/Makefile.inc
include $(COCOTB)/Makefile.sim

GTK_SAVEFILE := $(wildcard sim_build/*.gtkw)

gtkwave:
	gtkwave sim_build/$(TOPLEVEL).vcd $(GTK_SAVEFILE)
