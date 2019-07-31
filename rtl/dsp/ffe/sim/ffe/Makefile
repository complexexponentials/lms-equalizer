
export COCOTB_REDUCED_LOG_FMT
export PYTHONPATH:=$(realpath tests):$(PYTHONPATH)

LANG=verilog
SIM=icarus

SPATH = $(PWD)/../..
VERILOG_SOURCES= $(SPATH)/ffe.v

COMPILE_ARGS = -Wall

TOPLEVEL=ffe

MODULE ?= test

COCOTB=$(shell cocotb-config --makefiles)
include $(COCOTB)/Makefile.inc
include $(COCOTB)/Makefile.sim

GTK_SAVEFILE := $(wildcard sim_build/*.gtkw)

gtkwave:
	gtkwave sim_build/$(TOPLEVEL).vcd $(GTK_SAVEFILE)
