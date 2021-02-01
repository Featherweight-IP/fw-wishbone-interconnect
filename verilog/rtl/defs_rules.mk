#****************************************************************************
#* MKDV makefile fragement for fw-wishbone-interconnect
#* 
#* Adds sources required to use the fw-wishbone-interconnect RTL
#****************************************************************************
FW_WISHBONE_INTERCONNECT_RTLDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifneq (1,$(RULES))

ifeq (,$(findstring $(FW_WISHBONE_INTERCONNECT_RTLDIR), $(MKDV_INCLUDED_DEFS)))
MKDV_INCLUDED_DEFS += $(FW_WISHBONE_INTERCONNECT_RTLDIR)
MKDV_VL_INCDIRS += $(FW_WISHBONE_INTERCONNECT_RTLDIR)
MKDV_VL_SRCS += $(wildcard $(FW_WISHBONE_INTERCONNECT_RTLDIR)/*.v)
endif

else # Rules

endif
