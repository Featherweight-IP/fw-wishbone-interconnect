MKDV_MK := $(abspath $(lastword $(MAKEFILE_LIST)))
TEST_DIR := $(dir $(MKDV_MK))
MKDV_TOOL ?= sby

MKDV_VL_SRCS += $(wildcard $(TEST_DIR)/*.sv)
SBY_DEPTH ?= 128

SBY_OPTIONS += mode=bmc expect=pass,fail


TOP_MODULE = wb_interconnect_2x2_tb

include $(TEST_DIR)/../../common/defs_rules.mk

RULES := 1

include $(TEST_DIR)/../../common/defs_rules.mk

