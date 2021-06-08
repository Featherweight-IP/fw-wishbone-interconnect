/****************************************************************************
 * wb_interconnect_1xN.v
 * 
 * Completely-combinatorial single-initiator Wishbone interconnect
 ****************************************************************************/
`include "wishbone_tag_macros.svh"

/**
 * Module: wb_interconnect_1xN
 * 
 * TODO: Add module documentation
 */
module wb_interconnect_tag_1xN #(
		parameter 									ADR_WIDTH=32,
		parameter 									DAT_WIDTH=32,
		parameter									TGA_WIDTH=4,
		parameter									TGD_WIDTH=4,
		parameter									TGC_WIDTH=4,
		parameter 									N_TARGETS=1,
		parameter [N_TARGETS*ADR_WIDTH-1:0] 	T_ADR_MASK = {
			{8'hFF, {24{1'b0}} }
		},
		parameter [N_TARGETS*ADR_WIDTH-1:0] 	T_ADR = {
			{ 32'h2800_0000 }
		}
		) (
		input										clock,
		input										reset,
		
		// Target ports into the interconnect
		`WB_TAG_TARGET_PORT(t_, ADR_WIDTH, DAT_WIDTH, TGD_WIDTH, TGA_WIDTH, TGC_WIDTH),
		
		// Initiator ports out of the interconnect
		`WB_TAG_INITIATOR_PORT_ARR(i_, ADR_WIDTH, DAT_WIDTH, TGD_WIDTH, TGA_WIDTH, TGC_WIDTH, N_TARGETS)
		);
	
	localparam NO_TARGET  = {($clog2(N_TARGETS)+1){1'b1}};
	
	// Each initiator has a request vector -> Which target is desired
	//
	// Each target has an arbiter -> Which initiator has access
	//
	// When the two match, the initiator and target are connected
	//
	//

	// synopsys translate_off
	integer ii;
	initial begin
		for (ii=0; ii<N_TARGETS; ii=ii+1) begin
			$display("%0d MASK='h%08h ADDR='h%08h", ii, 
					T_ADR_MASK[ADR_WIDTH*ii+:ADR_WIDTH],
					T_ADR[ADR_WIDTH*ii+:ADR_WIDTH]);
		end
	end
	// synopsys translate_on
	
	// Decode logic
	// selected_target contains the index of the selected target
	// (0..N_TARGETS-1) or N_TARGETS if no address matched
	reg[$clog2(N_TARGETS):0]			selected_target;
	
	integer t_adr_i;
	always @* begin
		selected_target = NO_TARGET;
		for (t_adr_i=0; t_adr_i<N_TARGETS; t_adr_i=t_adr_i+1) begin
			if ((t_adr & T_ADR_MASK[ADR_WIDTH*t_adr_i+:ADR_WIDTH]) == T_ADR[ADR_WIDTH*t_adr_i+:ADR_WIDTH]) begin
				selected_target = N_TARGETS-t_adr_i-1;
			end
		end
	end
	
	// WB signals from target back to initiator
	
	// synopsys translate_off
	always @(posedge clock or posedge reset) begin
		if (t_cyc && t_stb && t_ack && selected_target == NO_TARGET) begin
			$display("%m Error: Address 'h%08x does not match a target", t_adr);
		end
	end
	// synopsys translate_on
	
	// TODO: how should we handle error responses?
	assign t_ack = (selected_target == NO_TARGET)?1'b1:i_ack[selected_target];
	assign t_err = (selected_target == NO_TARGET)?1'b1:i_err[selected_target];
	assign t_dat_r = i_dat_r[selected_target];
	assign t_tgd_r = i_tgd_r[selected_target*TGD_WIDTH+:TGD_WIDTH];
	
	// Initiator to target mux
	generate
		genvar i2t_mux_i;
		for (i2t_mux_i=0; i2t_mux_i<N_TARGETS; i2t_mux_i=i2t_mux_i+1) begin : i2t_mux

			// Route address, data, and we straight through
			assign i_adr[ADR_WIDTH*i2t_mux_i+:ADR_WIDTH] = t_adr;
			assign i_dat_w[DAT_WIDTH*i2t_mux_i+:DAT_WIDTH] = t_dat_w;
			assign i_sel[(DAT_WIDTH/8)*i2t_mux_i+:(DAT_WIDTH/8)] = t_sel;
			assign i_we[i2t_mux_i] = t_we;
			assign i_tga[i2t_mux_i*TGA_WIDTH+:TGA_WIDTH] = t_tga;
			assign i_tgc[i2t_mux_i*TGC_WIDTH+:TGC_WIDTH] = t_tgc;

			// Be selective with cyc and stb
			assign i_cyc[i2t_mux_i] = (selected_target == i2t_mux_i)?t_cyc:1'b0;
			assign i_stb[i2t_mux_i] = (selected_target == i2t_mux_i)?t_stb:1'b0;
		end
	endgenerate
	
endmodule

