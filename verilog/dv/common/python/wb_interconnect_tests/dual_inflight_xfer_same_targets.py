'''
Created on May 16, 2021

@author: mballance
'''
import cocotb
from wb_interconnect_tests.test_base import TestBase

class DualInflightXferSameTargets(TestBase):
    
    async def run(self):
        if len(self.initiator_bfms) < 2 or len(self.target_bfms) < 2:
            print("Note: skipping test")

        for ti_1 in range(len(self.target_mgrs)):
            for ii_1 in range(len(self.initiator_mgrs)):
                for ii_2 in range(ii_1+1,len(self.initiator_mgrs)):
                    print("(%d,%d) -> %d" % (ii_1,ii_2,ti_1))
                    t1 = self.target_mgrs[ti_1]
                    i1 = self.initiator_mgrs[ii_1]
                    i2 = self.initiator_mgrs[ii_2]

                    wt1 = cocotb.fork(i1.write(
                        t1.base_adr | (ii_1 << 24),
#                        ti_1+ii_1,
                        0x11111111,
                        0xF))
                    wt2 = cocotb.fork(i2.write(
                        t1.base_adr | (ii_2 << 24),
#                        ti_1+ii_2,
                        0x22222222,
                        0xF))
                    await cocotb.triggers.Combine(wt1, wt2)
                        
    
@cocotb.test()
async def entry(dut):
    t = DualInflightXferSameTargets()
    await t.init()
    await t.run()