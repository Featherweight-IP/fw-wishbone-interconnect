'''
Created on Feb 1, 2021

@author: mballance
'''
import cocotb
import pybfms
from wishbone_bfms.wb_initiator_bfm import WbInitiatorBfm
from wishbone_bfms.wb_target_bfm import WbTargetBfm

@cocotb.test()
async def entry(top):
    await pybfms.init()
    
    i0 : WbInitiatorBfm = pybfms.find_bfm(".*u_i0")
    i1 : WbInitiatorBfm = pybfms.find_bfm(".*u_i1")
    t0 : WbTargetBfm = pybfms.find_bfm(".*u_t0")
    t1 : WbTargetBfm = pybfms.find_bfm(".*u_t1")

    await cocotb.triggers.Combine(
        cocotb.fork(i0.write(0x10000000, 0x55aaeeff, 0xf)),
        cocotb.fork(i1.write(0x20000000, 0x55aaeeff, 0xf)))

    pass
