/****************************************************************************
 * wb_interconnect_NxN.sv
 * 
 * Completely-combinatorial  Wishbone interconnect
 ****************************************************************************/
`include "wishbone_macros.svh"

/**
 * Module: wb_interconnect_NxN
 * 
 * TODO: Add module documentation
 */
module wb_interconnect_NxN #(
		parameter 									WB_ADDR_WIDTH=32,
		parameter 									WB_DATA_WIDTH=32,
		parameter 									N_INITIATORS=1,
		parameter 									N_TARGETS=1,
		parameter [N_INITIATORS*WB_ADDR_WIDTH-1:0] 	I_ADR_MASK = {
			{8'hFF, {24{1'b0}} }
		},
		parameter [N_TARGETS*WB_ADDR_WIDTH-1:0] 		T_ADR = {
			{ 32'h2800_0000 }
		}
		) (
		input										clk,
		input										rst,
		// Target ports into the interconnect
		`WB_TARGET_PORT_ARR(,WB_ADDR_WIDTH,WB_DATA_WIDTH,N_INITIATORS),
	
		// Initiator ports out of the interconnect
		`WB_INITIATOR_PORT_ARR(t,WB_ADDR_WIDTH,WB_DATA_WIDTH,N_TARGETS)
		);
	
	localparam WB_DATA_MSB = (WB_DATA_WIDTH-1);
	localparam N_INIT_ID_BITS = (N_INITIATORS>1)?$clog2(N_INITIATORS):1;
	localparam N_TARG_ID_BITS = $clog2(N_TARGETS+1);
	localparam NO_TARGET  = {(N_TARG_ID_BITS+1){1'b1}};
	localparam NO_INITIATOR = {(N_INIT_ID_BITS+1){1'b1}};
	
	// Interface to the decode-fail target
//	wb_if				terr();

//	function [N_TARG_ID_BITS:0] addr2targ_id(
//		input reg[N_INIT_ID_BITS-1:0]		initiator,
//		input reg[WB_ADDR_WIDTH-1:0] 		addr
//		);
//		integer i;
//		begin
//		addr2targ_id = N_TARGETS;
////		$display("addr2targ_id: 'h%08h 'h%08h", addr, ADDR_RANGES);
//		for (i=0; i<N_TARGETS; i+=1) begin
////			$display("Address Range: %0d 'h%08h..'h%08h", i, 
////					ADDR_RANGES[(WB_ADDR_WIDTH*(i+2)-1)-:WB_ADDR_WIDTH],
////					ADDR_RANGES[(WB_ADDR_WIDTH*(i+1)-1)-:WB_ADDR_WIDTH]);
////			$display("  %0d %0d", (WB_ADDR_WIDTH*(i+2)-1), (WB_ADDR_WIDTH*(i+1)-1));
//			if (
//					(addr&I_ADR_MASK[(WB_ADDR_WIDTH*(i+1))-1-:WB_ADDR_WIDTH]) == 
//					(T_ADR[(WB_ADDR_WIDTH*(i+1))-1-:WB_ADDR_WIDTH])) begin
//				$display("Address 'h%08h: range=%0d", addr, N_TARGETS-1);
//				addr2targ_id = N_TARGETS-1;
//			end
//		end
//		end
//	endfunction

	// Each initiator has a request vector -> Which target is desired
	//
	// Each target has an arbiter -> Which initiator has access
	//
	// When the two match, the initiator and target are connected
	//
	//
	
	// Decode logic
	// This vector contains an element for each initiator and target,
	// and are one-hot encoded. 
	//
	// target_initiator_sel - per-target request vector. Sent to target arbiters. 
	//                        Consists of a vector of initiators wishing to access the target
	// initiator_target_sel - per-initator request vector. 
	//                        Consists of a vector representing the target an initiator is accessing
	wire[N_TARGETS-1:0]	      initiator_target_sel[N_INITIATORS-1:0];
	wire[N_INITIATORS-1:0]    target_initiator_sel[N_TARGETS-1:0];
	generate
		genvar md_i, md_t_i;
		for (md_i=0; md_i<N_INITIATORS; md_i=md_i+1) begin : block_md_i
			for (md_t_i=0; md_t_i<N_TARGETS; md_t_i=md_t_i+1) begin : block_md_t_i
				assign target_initiator_sel[N_TARGETS-md_t_i-1][md_i] = 
					((adr[WB_ADDR_WIDTH*md_i+:WB_ADDR_WIDTH]&I_ADR_MASK[WB_ADDR_WIDTH*md_i+:WB_ADDR_WIDTH])
						== T_ADR[WB_ADDR_WIDTH*md_t_i+:WB_ADDR_WIDTH]);
				assign initiator_target_sel[md_i][md_t_i] = target_initiator_sel[md_t_i][md_i];
			end
		end
	endgenerate

//	// Initiator state machine
//	reg[2:0]							initiator_state[N_INITIATORS-1:0];
	
	
	// Per-target grant vector
	wire[N_INITIATORS-1:0]				initiator_gnt[N_TARGETS-1:0];
//	wire[$clog2(N_INITIATORS)-1:0]		initiator_gnt_id[N_TARGETS:0];
//	wire[N_INITIATORS-1:0]				initiator_target_req[N_TARGETS:0];
//	
//	generate
//		genvar m_i;
//		for (m_i=0; m_i<N_INITIATORS; m_i=m_i+1) begin : block_m_i
//			always @(posedge clk) begin
//				if (rst == 1) begin
//					initiator_state[m_i] <= 0;
//					initiator_active_target[m_i] <= NO_TARGET;
//				end else begin
//					case (initiator_state[m_i])
//						0: begin
//							if (cyc[m_i] && stb[m_i]) begin
//								initiator_state[m_i] <= 1;
//								initiator_active_target[m_i] <= initiator_target_sel[N_TARGETS*m_i+:N_TARGETS];
////								$display("Master %0d => Slave %0d", m_i, addr2targ_id(m_i, adr[m_i]));
//							end
//						end
//						
//						1: begin
//							// Wait for the addressed target to acknowledge
//							if (cyc[m_i] && stb[m_i] && ack[m_i]) begin
//								initiator_state[m_i] <= 0;
//								initiator_active_target[N_TARGETS*m_i+:N_TARGETS] <= {N_TARGETS{1'b0}};
//							end
//						end
//					endcase
//				end
//			end
//		end
//	endgenerate

//	// Build the req vector for each target
//	// This vector aggregates requests from each initiator for a given target
//	generate
//		genvar m_req_i, m_req_j;
//
//		for (m_req_i=0; m_req_i <(N_TARGETS+1); m_req_i=m_req_i+1) begin : block_m_req_i
//			for (m_req_j=0; m_req_j < N_INITIATORS; m_req_j=m_req_j+1) begin : block_m_req_j
//				assign initiator_target_req[m_req_i][m_req_j] = (initiator_active_target[m_req_j] == m_req_i);
//			end
//		end
//	endgenerate

	generate
		genvar t_arb_i;
		
		for (t_arb_i=0; t_arb_i<N_TARGETS; t_arb_i=t_arb_i+1) begin : s_arb
			wb_interconnect_arb #(
				.N_REQ  (N_INITIATORS)
				) 
				aw_arb (
					.clk    (clk   ), 
					.rst    (rst  ), 
					// Request vector
					.req    (target_initiator_sel[t_arb_i]),
					// One-hot grant vector
					.gnt    (initiator_gnt[t_arb_i])
				);
		end
	endgenerate

	reg[N_INIT_ID_BITS:0]					target_active_initiator[N_TARGETS-1:0];
	generate
		// For each target, determine which initiator is connected
		genvar t_ai_i;
		integer t_ai_ii;
		for (t_ai_i=0; t_ai_i<N_TARGETS; t_ai_i=t_ai_i+1) begin : block_t_ai
			always @* begin
				target_active_initiator[t_ai_i] = NO_INITIATOR;
				for (t_ai_ii=0; t_ai_ii<N_INITIATORS; t_ai_ii=t_ai_ii+1) begin
					if (initiator_gnt[t_ai_i][t_ai_ii]) begin
						target_active_initiator[t_ai_i] = t_ai_ii;
					end
				end
			end
		end
	endgenerate
	
	// Per-initiator id of the selected target
	// Controls response-path muxing
	reg[N_TARG_ID_BITS-1:0]				initiator_active_target[N_INITIATORS-1:0];
	generate
		// For each initiator, determine which target is selected and granted
		genvar i_at_i;
		integer i_at_ii;
		for (i_at_i=0; i_at_i<N_INITIATORS; i_at_i=i_at_i+1) begin : block_i_at
			always @* begin
				initiator_active_target[i_at_i] = NO_TARGET;
				for (i_at_ii=0; i_at_ii<N_TARGETS; i_at_ii=i_at_ii+1) begin
					// TODO: 
					if (initiator_target_sel[i_at_i][i_at_ii]) begin
						initiator_active_target[i_at_i] = i_at_ii;
					end
				end
			end
		end
	endgenerate
			
	
//	reg[N_INIT_ID_BITS:0]					target_active_initiator[N_TARGETS:0];
//	generate
//	// For each target, determine which initiator is connected
//		genvar t_ai_i;
//		integer t_ai_ii;
//		for (t_ai_i=0; t_ai_i<N_TARGETS; t_ai_i=t_am_i+1) begin : block_t_ai
//			always @* begin
//				target_active_initiator[t_ai_i] = NO_INITIATOR;
//				for (t_ai_ii=0; t_ai_ii<N_INITIATORS; t_ai_ii=t_ai_ii+1) begin
//					if (initiator_gnt[t_ai_i][t_ai_ii]) begin
//						target_active_initiator[t_ai_i] = t_ai_ii;
//					end
//				end
//			end
//		end
//	endgenerate	
	
	// WB signals from target back to initiator
	generate
		genvar t2i_i;
		
		for (t2i_i=0; t2i_i<N_INITIATORS; t2i_i=t2i_i+1) begin : block_t2i_i
			assign dat_r[WB_DATA_WIDTH*t2i_i+:WB_DATA_WIDTH] = 
				(initiator_active_target[t2i_i] != NO_TARGET)?
					tdat_r[WB_DATA_WIDTH*initiator_active_target[t2i_i]+:WB_DATA_WIDTH]:
						{WB_DATA_WIDTH{1'b0}};
			assign err[t2i_i] = (initiator_active_target[t2i_i] != NO_TARGET)?
					terr[initiator_active_target[t2i_i]]:1'b0;
			assign ack[t2i_i] = (initiator_active_target[t2i_i] != NO_TARGET)?
					tack[initiator_active_target[t2i_i]]:1'b0;
//			assign dat_r[WB_DATA_WIDTH*t2i_i+:WB_DATA_WIDTH] = 
//				(initiator_active_target[t2i_i] != NO_TARGET && 
//						initiator_gnt[initiator_active_target[t2i_i]] && 
//						initiator_gnt_id[initiator_active_target[t2i_i]] == t2i_i)?
//					tdat_r[WB_DATA_WIDTH*initiator_active_target[t2i_i]+:WB_DATA_WIDTH]:0;
//			assign err[t2i_i] = (initiator_active_target[t2i_i] != NO_TARGET && 
//										initiator_gnt[initiator_active_target[t2i_i]] && 
//										initiator_gnt_id[initiator_active_target[t2i_i]] == t2i_i)?
//										terr[initiator_active_target[t2i_i]]:0;
//			assign ack[t2i_i] = (initiator_active_target[t2i_i] != NO_TARGET && 
//										initiator_gnt[initiator_active_target[t2i_i]] && 
//										initiator_gnt_id[initiator_active_target[t2i_i]] == t2i_i)?
//										tack[initiator_active_target[t2i_i]]:0;
		end
	endgenerate

	// Initiator to target mux
	generate
		genvar i2t_mux_i;
		for(i2t_mux_i=0; i2t_mux_i<N_TARGETS; i2t_mux_i=i2t_mux_i+1) begin : i2t_mux
			assign tadr[WB_ADDR_WIDTH*i2t_mux_i+:WB_ADDR_WIDTH] = 
				(target_active_initiator[i2t_mux_i] == NO_INITIATOR)?{WB_ADDR_WIDTH{1'b0}}:
					adr[WB_ADDR_WIDTH*target_active_initiator[i2t_mux_i]+:WB_ADDR_WIDTH];
			assign tdat_w[WB_DATA_WIDTH*i2t_mux_i+:WB_DATA_WIDTH] = 
				(target_active_initiator[i2t_mux_i] == NO_INITIATOR)?{WB_DATA_WIDTH{1'b0}}:
					dat_w[WB_DATA_WIDTH*target_active_initiator[i2t_mux_i]+:WB_DATA_WIDTH];
			assign tcyc[i2t_mux_i] = 
				(target_active_initiator[i2t_mux_i] == NO_INITIATOR)?1'b0:
					cyc[target_active_initiator[i2t_mux_i]];
			assign tsel[(WB_DATA_WIDTH/8)*i2t_mux_i+:(WB_DATA_WIDTH/8)] = 
				(target_active_initiator[i2t_mux_i] == NO_INITIATOR)?{(WB_DATA_WIDTH/8){1'b0}}:
				sel[(WB_DATA_WIDTH/8)*target_active_initiator[i2t_mux_i]+:(WB_DATA_WIDTH/8)];
			assign tstb[i2t_mux_i] = 
				(target_active_initiator[i2t_mux_i] == NO_INITIATOR)?1'b0:
					stb[target_active_initiator[i2t_mux_i]];
			assign twe[i2t_mux_i] = 
				(target_active_initiator[i2t_mux_i] == NO_INITIATOR)?1'b0:
					we[target_active_initiator[i2t_mux_i]];
		end
	endgenerate
	
//	// Error target
//	reg err_req;
//	always @(posedge clk) begin
//		if (rst == 1) begin
//			err_req <= 0;
//		end else begin
//			if (tstb[N_TARGETS] && tcyc[N_TARGETS] && !err_req) begin
//				err_req <= 1;
//			end else begin
//				err_req <= 0;
//			end
//		end
//	end
endmodule

