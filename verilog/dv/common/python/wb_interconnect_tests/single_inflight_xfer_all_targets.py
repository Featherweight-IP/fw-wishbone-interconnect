'''
Created on May 16, 2021

@author: mballance
'''
import cocotb
from wb_interconnect_tests.test_base import TestBase

class SingleInflightXferAllTargets(TestBase):
    
    async def run(self):
        for ti,t in enumerate(self.target_mgrs):
            for ii,i in enumerate(self.initiator_mgrs):
                await i.write(
                    t.base_adr | (ii << 24),
                    ti+ii,
                    0xF)
        pass
    
@cocotb.test()
async def entry(dut):
    t = SingleInflightXferAllTargets()
    await t.init()
    await t.run()