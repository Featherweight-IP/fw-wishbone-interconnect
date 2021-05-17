
FW_WISHBONE_INTERCONNECT_DV_COMMONDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
FW_WISHBONE_INTERCONNECT_DIR := $(abspath $(FW_WISHBONE_INTERCONNECT_DV_COMMONDIR)/../../..)
PACKAGES_DIR := $(FW_WISHBONE_INTERCONNECT_DIR)/packages
DV_MK := $(shell PATH=$(PACKAGES_DIR)/python/bin:$(PATH) python -m mkdv mkfile)

ifneq (1,$(RULES))

include $(PACKAGES_DIR)/fwprotocol-defs/verilog/rtl/defs_rules.mk
include $(FW_WISHBONE_INTERCONNECT_DIR)/verilog/rtl/defs_rules.mk

MKDV_PYTHONPATH += $(FW_WISHBONE_INTERCONNECT_DV_COMMONDIR)/python

MKDV_VL_SRCS += $(wildcard $(FW_WISHBONE_INTERCONNECT_DV_COMMONDIR)/*.sv)

include $(DV_MK)
else # Rules

include $(DV_MK)
endif
