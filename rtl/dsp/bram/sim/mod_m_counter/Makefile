
export COCOTB_REDUCED_LOG_FMT
export PYTHONPATH:=$(realpath tests):$(PYTHONPATH)

LANG=verilog
SIM=icarus

SPATH = $(PWD)/../..
VERILOG_SOURCES= $(SPATH)/mod_m_counter.v
			 
TOPLEVEL=mod_m_counter

MODULE ?= test

COCOTB=$(shell cocotb-config --makefiles)
include $(COCOTB)/Makefile.inc
include $(COCOTB)/Makefile.sim

GTK_SAVEFILE := $(wildcard sim_build/*.gtkw)

gtkwave:
	gtkwave sim_build/mod_m_counter.vcd $(GTK_SAVEFILE)
