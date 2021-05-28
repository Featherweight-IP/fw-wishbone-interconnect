FW_WISHBONE_INTERCONNECT_DBGDIR := $(dir $(lastword $(MAKEFILE_LIST)))

ifneq (1,$(RULES))

ifeq (,$(findstring $(FW_WISHBONE_INTERCONNECT_DBGDIR),$(MKDV_INCLUDED_DEFS)))
MKDV_PYTHONPATH += $(FW_WISHBONE_INTERCONNECT_DBGDIR)/python
MKDV_VL_INCDIRS += $(PACKAGES_DIR)/fwprotocol-defs/verilog/rtl/defs_rules.mk

MKDV_VL_DEFINES += FW_WB_INTERCONNECT_TAG_NXN_DBG_MODULE=wb_interconnect_tag_NxN_dbg_bfm

MKDV_VL_SRCS += $(wildcard $(FW_WISHBONE_INTERCONNECT_DBGDIR)/*.v)

PYBFMS_MODULES += fw_wishbone_interconnect_bfms

endif

else # Rules

endif
