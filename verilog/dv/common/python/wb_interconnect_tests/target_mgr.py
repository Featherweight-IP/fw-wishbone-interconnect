'''
Created on May 16, 2021

@author: mballance
'''
from assertpy import *
from wishbone_bfms.wb_target_bfm import WbTargetBfm

class TargetMgr(object):
    
    def __init__(self, idx, base_adr, target_bfm):
        self.idx = idx
        self.base_adr = base_adr
        self.target_bfm : WbTargetBfm = target_bfm
        self.target_bfm.set_responder(self.access)
        self.exp_response_data = {}
        
    def set_exp_data(self, initiator_id, dat):
        print("set_exp_data: %d 0x%08x (%s)" % (initiator_id,dat, self.target_bfm.bfm_info.inst_name))
        if not initiator_id in self.exp_response_data.keys():
            self.exp_response_data[initiator_id] = []
        self.exp_response_data[initiator_id].append(dat)    
        pass
        
    def access(self,
               bfm,
               adr,
               we,
               sel,
               dat_w):
        if not self.target_bfm.is_reset:
            print("Skipping because pre-reset")
            return
        
        initiator_id = (adr >> 24) & 0xF
        
        print("TargetMgr[%d]::access initiator_id=%d sz=%d 0x%08x %d %x 0x%08x (%s)" % (
            self.idx, initiator_id, len(self.exp_response_data), adr, we, sel, dat_w,
            self.target_bfm.bfm_info.inst_name))
        
#        assert_that(initiator_id).is_in(self.exp_response_data.keys())
        exp_data = self.exp_response_data[initiator_id]
        
        assert_that(len(exp_data)).is_greater_than(0)
        data = exp_data.pop(0)
        if we:
            # It's a write. Acknowledge the access
            self.target_bfm.access_ack(data, 0)
            assert_that(dat_w).is_equal_to(data)
        else:
            # It's a read. Send back the next data
            self.target_bfm.access_ack(data, 0)
        
        