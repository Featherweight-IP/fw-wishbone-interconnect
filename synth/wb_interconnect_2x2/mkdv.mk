MKDV_MK:=$(abspath $(lastword $(MAKEFILE_LIST)))
TEST_DIR := $(dir $(MKDV_MK))
PACKAGES_DIR := $(abspath $(TEST_DIR)/../../packages)
DV_MK := $(shell $(PACKAGES_DIR)/python/bin/python -m mkdv mkfile)

MKDV_TOOL ?= openlane

TOP_MODULE = wb_interconnect_2x2

MKDV_VL_INCDIRS += $(PACKAGES_DIR)/fwprotocol-defs/src/sv

MKDV_VL_SRCS += $(TEST_DIR)/../../verilog/rtl/wb_interconnect_NxN.v
MKDV_VL_SRCS += $(TEST_DIR)/../../verilog/rtl/wb_interconnect_arb.v
MKDV_VL_SRCS += $(TEST_DIR)/wb_interconnect_2x2.v

include $(DV_MK)

RULES := 1

include $(DV_MK)



