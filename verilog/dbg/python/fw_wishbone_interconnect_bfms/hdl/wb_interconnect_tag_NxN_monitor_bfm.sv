/****************************************************************************
 * wb_interconnect_tag_NxN_monitor_bfm.sv
 ****************************************************************************/
`include "wishbone_tag_macros.svh"

/**
 * Module: wb_interconnect_tag_NxN_monitor_bfm
 * 
 * TODO: Add module documentation
 */
module wb_interconnect_tag_NxN_monitor_bfm #(
		parameter								IS_INITIATOR = 0,
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
		
		`WB_TAG_MONITOR_PORT(m_, ADR_WIDTH, DAT_WIDTH, TGD_WIDTH, TGA_WIDTH, TGC_WIDTH),
		
		// Provides the ID of the initiator granted access 
		// when this BFM is monitoring a target interface
		input[$clog2(N_INITIATORS)-1:0]		target_initiator
		);
	
	localparam MSG_SZ = 32;
	
	reg 				state = 0;
	reg[8*MSG_SZ-1:0]	xaction = {8*MSG_SZ{1'b0}};

	reg[$clog2(N_TARGETS):0]		target;
	
	integer adr_i;
	always @* begin
		target = {$clog2(N_TARGETS)+1{1'b1}};
		for (adr_i=0; adr_i<N_TARGETS; adr_i=adr_i+1) begin
			if ((m_adr&T_ADR_MASK[ADR_WIDTH*adr_i+:ADR_WIDTH]) == T_ADR[ADR_WIDTH*adr_i+:ADR_WIDTH]) begin
				target = (N_TARGETS-adr_i-1);
			end
		end
	end
	
	always @(posedge clock or posedge reset) begin
		if (reset) begin
			state <= 0;
		end else begin
			case (state)
				0: begin // Wait for cycle start
					if (m_cyc && m_stb) begin
						_start_cycle(
								(IS_INITIATOR)?target:target_initiator,
								m_adr,
								m_tga,
								m_dat_w,
								m_tgd_w,
								(m_we)?m_sel:0,
								m_tgc);
						state <= 1;
					end
				end
				1: begin
					if (m_cyc && m_stb && m_ack) begin
						// Access complete
						_end_cycle(
								m_dat_r,
								m_tgd_r);
						state <= 0;
					end
				end
			endcase
		end
	end
	
	task init;
	begin
		_set_parameters(IS_INITIATOR);
	end
	endtask
	
	task _clr_xaction;
		xaction = {8*MSG_SZ{1'b0}};
	endtask
	
	task _set_xaction_c(input[7:0] idx, input[7:0] c);
	begin
		idx = MSG_SZ-idx-1;
		xaction = ((xaction & ~('hFF << 8*idx)) | (c << 8*idx));
	end
	endtask
	
    // Auto-generated code to implement the BFM API
`ifdef PYBFMS_GEN
${pybfms_api_impl}
`endif

endmodule


