'''
Created on May 16, 2021

@author: mballance
'''

import cocotb
import pybfms
from typing import List
from wishbone_bfms.wb_initiator_bfm import WbInitiatorBfm
from wishbone_bfms.wb_target_bfm import WbTargetBfm
from wb_interconnect_tests.initiator_mgr import InitiatorMgr
from wb_interconnect_tests.target_mgr import TargetMgr

class TestBase(object):
    
    def __init__(self):
        self.initiator_bfms = []
        self.target_bfms = []
    
    async def init(self):
        await pybfms.init()
        
        initiators : List[WbInitiatorBfm] = pybfms.find_bfms(
            ".*u_initiator_bfm", WbInitiatorBfm)
        targets : List[WbTargetBfm] = pybfms.find_bfms(
            ".*u_target_bfm", WbTargetBfm)

        i_list = []
        t_list = []
        for i in initiators:
            print("Initiator: " + i.bfm_info.inst_name)        
            lb_idx = i.bfm_info.inst_name.find('[')
            rb_idx = i.bfm_info.inst_name.find(']', lb_idx)
            idx = int(i.bfm_info.inst_name[lb_idx+1:rb_idx])
            i_list.append((idx,i))
            print("  index: " + str(idx))
        for t in targets:
            print("Target: " + t.bfm_info.inst_name)
            lb_idx = t.bfm_info.inst_name.find('[')
            rb_idx = t.bfm_info.inst_name.find(']', lb_idx)
            idx = int(t.bfm_info.inst_name[lb_idx+1:rb_idx])
            t_list.append((idx,t))
            print("  index: " + str(idx))

        i_list.sort(key=lambda i: i[0])
        t_list.sort(key=lambda i: i[0])
        
        self.initiator_bfms = list(map(lambda i: i[1], i_list))
        self.target_bfms = list(map(lambda t: t[1], t_list))
       
        n_initiators = len(self.initiator_bfms)
        n_targets = len(self.target_bfms)
        
        self.target_mgrs = []
        for ti,t in enumerate(self.target_bfms):
            print("i=%d t=%s" % (ti, t.bfm_info.inst_name))
            self.target_mgrs.append(TargetMgr(
                ti, 
#                (17-n_targets-ti) << 28,
                ti << 28,
                t))
            
        self.initiator_mgrs = []
        for i,ii in enumerate(self.initiator_bfms):
            self.initiator_mgrs.append(InitiatorMgr(i, ii, self.target_mgrs))
            
        print("initiator_bfms: " + str(self.initiator_bfms))
        print("target_bfms: " + str(self.target_bfms))
    
    async def run(self):
        pass

@cocotb.test()
async def entry(dut):
    t = TestBase()
    await t.init()
    await t.run()
    
    