/****************************************************************************
 * wb_interconnect_tag_NxN_dbg_bfm.sv
 ****************************************************************************/
`include "wishbone_tag_macros.svh"
  
/**
 * Module: wb_interconnect_tag_NxN_dbg_bfm
 * 
 * TODO: Add module documentation
 */
module wb_interconnect_tag_NxN_dbg_bfm #(
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

	// Create monitors for all initiator ports
	generate
		genvar init_i;
		for (init_i=0; init_i<N_INITIATORS; init_i=init_i+1) begin : initiator_mon
			wb_interconnect_tag_NxN_monitor_bfm #(
				.IS_INITIATOR      (1     ), 
				.ADR_WIDTH         (ADR_WIDTH        ), 
				.DAT_WIDTH         (DAT_WIDTH        ), 
				.TGC_WIDTH         (TGC_WIDTH        ), 
				.TGA_WIDTH         (TGA_WIDTH        ), 
				.TGD_WIDTH         (TGD_WIDTH        ), 
				.N_INITIATORS      (N_INITIATORS     ), 
				.N_TARGETS         (N_TARGETS        ), 
				.T_ADR_MASK        (T_ADR_MASK       ), 
				.T_ADR             (T_ADR            )
				) u_mon (
				.clock             (clock            ), 
				.reset             (reset            ), 
				`WB_TAG_CONNECT_ARR(m_, i_, init_i, ADR_WIDTH, 
					DAT_WIDTH, TGD_WIDTH, TGA_WIDTH, TGC_WIDTH),
				.target_initiator  ({$clog2(N_INITIATORS){1'b0}}));
		end
	endgenerate

	// Create monitors for all target ports
	generate
		genvar targ_i;
		for (targ_i=0; targ_i<N_TARGETS; targ_i=targ_i+1) begin : target_mon
			wb_interconnect_tag_NxN_monitor_bfm #(
				.IS_INITIATOR      (0     ), 
				.ADR_WIDTH         (ADR_WIDTH        ), 
				.DAT_WIDTH         (DAT_WIDTH        ), 
				.TGC_WIDTH         (TGC_WIDTH        ), 
				.TGA_WIDTH         (TGA_WIDTH        ), 
				.TGD_WIDTH         (TGD_WIDTH        ), 
				.N_INITIATORS      (N_INITIATORS     ), 
				.N_TARGETS         (N_TARGETS        ), 
				.T_ADR_MASK        (T_ADR_MASK       ), 
				.T_ADR             (T_ADR            )
				) u_mon (
				.clock             (clock            ), 
				.reset             (reset            ), 
				`WB_TAG_CONNECT_ARR(m_, t_, targ_i, ADR_WIDTH, 
					DAT_WIDTH, TGD_WIDTH, TGA_WIDTH, TGC_WIDTH),
				.target_initiator  (
					target_initiator[targ_i*$clog2(N_INITIATORS)+:$clog2(N_INITIATORS)]));
		end
	endgenerate
	
	task init;
	begin
	end
	endtask
	
    // Auto-generated code to implement the BFM API
`ifdef PYBFMS_GEN
${pybfms_api_impl}
`endif

endmodule


