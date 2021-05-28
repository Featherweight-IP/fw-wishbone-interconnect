'''
Created on May 27, 2021

@author: mballance
'''

import pybfms

@pybfms.bfm(hdl={
    pybfms.BfmType.Verilog : pybfms.bfm_hdl_path(__file__, "hdl/wb_interconnect_tag_NxN_monitor_bfm.sv"),
    pybfms.BfmType.SystemVerilog : pybfms.bfm_hdl_path(__file__, "hdl/wb_interconnect_tag_NxN_monitor_bfm.sv"),
    }, has_init=True)
class MonitorBfm():
    
    def __init__(self):
        self.is_initiator = False
        self.parent = None
        
        # Holds a map of initiator/target ID to name
        self.id_m = {}
        pass
   
    @pybfms.export_task(pybfms.uint8_t)
    def _set_parameters(self, is_initiator):
        self.is_initiator = is_initiator
        
    @pybfms.export_task(pybfms.uint8_t,pybfms.uint64_t,pybfms.uint32_t,pybfms.uint64_t,pybfms.uint32_t,pybfms.uint8_t,pybfms.uint8_t)
    def _start_cycle(self, 
                     init_targ_id,
                     adr,
                     tga,
                     dat_w,
                     tgd_w,
                     wstb,
                     tgc):
        xaction = ""
        name_m = self.parent.target_name_m if self.is_initiator else self.parent.initiator_name_m
      
        if init_targ_id in name_m.keys():
            name = name_m[init_targ_id]
        else:
            name = "%d" % init_targ_id
            
        if self.is_initiator:
            
            if wstb == 0:
                xaction = "rd: (%s) 0x%08x" % (name, adr)
            else:
                xaction = "wr: (%s) 0x%08x 0x%08x" % (name, adr, dat_w)
        else:
            if wstb == 0:
                xaction = "rd: (%s) 0x%08x" % (name, adr)
            else:
                xaction = "wr: (%s) 0x%08x 0x%08x" % (name, adr, dat_w)
        self._set_xaction(xaction)
 
    @pybfms.export_task(pybfms.uint64_t, pybfms.uint32_t)       
    def _end_cycle(self,
                   dat_r,
                   tgd_r):
        self._clr_xaction()

    def _set_xaction(self, msg):
        self._clr_xaction()
        for i,c in enumerate(msg.encode()):
            self._set_xaction_c(i, c)

    @pybfms.import_task()    
    def _clr_xaction(self):
        pass
    
    @pybfms.import_task(pybfms.uint8_t,pybfms.uint8_t)
    def _set_xaction_c(self, idx, c):
        pass
        
