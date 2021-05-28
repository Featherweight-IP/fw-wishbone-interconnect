/****************************************************************************
 * wb_interconnect_tag_NxN_dbg.v
 ****************************************************************************/
`include "wishbone_tag_macros.svh"
  
/**
 * Module: wb_interconnect_tag_NxN_dbg
 * 
 * TODO: Add module documentation
 */
module wb_interconnect_tag_NxN_dbg #(
		parameter 								ADR_WIDTH=32,
		parameter 								DAT_WIDTH=32,
		parameter 								TGC_WIDTH=4,
		parameter 								TGA_WIDTH=4,
		parameter 								TGD_WIDTH=4,
		parameter 								N_INITIATORS=1,
		parameter 								N_TARGETS=1,
		parameter [N_TARGETS*ADR_WIDTH-1:0] 	T_ADR_MASK = {
			{8'hFF, {24{1'b0}} }
		},
		parameter [N_TARGETS*ADR_WIDTH-1:0] 	T_ADR = {
			{ 32'h2800_0000 }
		}
		) (
		input			clock,
		input			reset,
		`WB_TAG_MONITOR_PORT_ARR(i_, ADR_WIDTH, DAT_WIDTH, TGD_WIDTH, TGA_WIDTH, TGC_WIDTH,N_INITIATORS),
		`WB_TAG_MONITOR_PORT_ARR(t_, ADR_WIDTH, DAT_WIDTH, TGD_WIDTH, TGA_WIDTH, TGC_WIDTH,N_TARGETS),
		input[($clog2(N_INITIATORS)*N_TARGETS)-1:0]		target_initiator
		);
	
`ifdef FW_WB_INTERCONNECT_TAG_NXN_DBG_MODULE
		`FW_WB_INTERCONNECT_TAG_NXN_DBG_MODULE #(
		.ADR_WIDTH(ADR_WIDTH),
			.DAT_WIDTH(DAT_WIDTH),
			.TGC_WIDTH(TGC_WIDTH),
			.TGA_WIDTH(TGA_WIDTH),
			.TGD_WIDTH(TGD_WIDTH),
			.N_INITIATORS(N_INITIATORS),
			.N_TARGETS(N_TARGETS),
			.T_ADR_MASK(T_ADR_MASK),
			.T_ADR(T_ADR)
		) u_dbg (
			.clock(clock),
			.reset(reset),
			`WB_TAG_CONNECT(i_, i_),
			`WB_TAG_CONNECT(t_, t_),
			.target_initiator(target_initiator)
		);
`endif

endmodule


