'''
Created on May 16, 2021

@author: mballance
'''
from assertpy import *
from wishbone_bfms.wb_initiator_bfm import WbInitiatorBfm

class InitiatorMgr(object):
    
    def __init__(self, 
                 initiator_id,
                 initiator_bfm, 
                 target_mgrs):
        self.initiator_id = initiator_id
        self.initiator_bfm : WbInitiatorBfm = initiator_bfm
        self.target_mgrs = target_mgrs
        

    async def write(self, adr, dat, sel):
        # TODO: First, ensure the target_mgr is expecting data
        target_id = (adr >> 28) & 0xF
        # target_id = 16-n_targets-ti
        # target_id+ti = 16-n_targets-target_id
#        target_idx = 16-len(self.target_mgrs)-target_id
        target_idx = target_id
        print("target_id=%d target_idx=%d" % (target_id,target_idx))
        assert_that(target_idx).is_less_than(len(self.target_mgrs))
        
        self.target_mgrs[target_idx].set_exp_data(self.initiator_id, dat)
        
        await self.initiator_bfm.write(adr, dat, sel)
        
    async def read(self, adr, dat):
        # TODO: Prime the target_mgr with expected data
        target_id = (adr >> 28) & 0xF
        assert_that(target_id).is_less_than(len(self.target_mgrs))
        
        self.target_mgrs[target_id].set_exp_data(self.initiator_id, dat)
        
        await self.initiator_bfm.read(adr)
