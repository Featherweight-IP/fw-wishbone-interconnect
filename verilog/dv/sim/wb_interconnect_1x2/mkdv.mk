
MKDV_MK := $(abspath $(lastword $(MAKEFILE_LIST)))
TEST_DIR := $(dir $(MKDV_MK))

MKDV_PLUGINS += cocotb pybfms
PYBFMS_MODULES += wishbone_bfms

TOP_MODULE=wb_interconnect_1x2_tb
VLSIM_CLKSPEC += clock=10ns
VLSIM_OPTIONS += -Wno-fatal

MKDV_VL_SRCS += $(TEST_DIR)/wb_interconnect_1x2_tb.sv
#MKDV_COCOTB_MODULE = wb_interconnect_tests.single_initiator_target
MKDV_COCOTB_MODULE = wb_interconnect_tests.parallel_initiator_target

include $(TEST_DIR)/../../common/defs_rules.mk

RULES := 1

include $(TEST_DIR)/../../common/defs_rules.mk
