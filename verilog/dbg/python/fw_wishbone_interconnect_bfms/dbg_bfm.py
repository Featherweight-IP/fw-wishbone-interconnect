'''
Created on May 27, 2021

@author: mballance
'''

import pybfms
from fw_wishbone_interconnect_bfms.monitor_bfm import MonitorBfm

@pybfms.bfm(hdl={
    pybfms.BfmType.Verilog : pybfms.bfm_hdl_path(__file__, "hdl/wb_interconnect_tag_NxN_dbg_bfm.sv"),
    pybfms.BfmType.SystemVerilog : pybfms.bfm_hdl_path(__file__, "hdl/wb_interconnect_tag_NxN_dbg_bfm.sv"),
    }, has_init=True)
class DbgBfm(object):
    
    def __init__(self):
        self.initiator_name_m = {}
        self.target_name_m = {}
        pass

    def bfm_init(self):
        inst_name = self.bfm_info.inst_name
    
        # Link the sub-BFMs up to the parent    
        for bfm in pybfms.find_bfms(".*", MonitorBfm):
            if bfm.bfm_info.inst_name.startswith(inst_name):
                bfm.parent = self
    
    pass

