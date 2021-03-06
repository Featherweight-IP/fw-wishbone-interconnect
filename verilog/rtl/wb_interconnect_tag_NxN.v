/****************************************************************************
 * wb_interconnect_NxN.sv
 * 
 * Completely-combinatorial  Wishbone interconnect
 ****************************************************************************/
`include "wishbone_tag_macros.svh"

/**
 * Module: wb_interconnect_NxN
 * 
 * Wishbone interconnect with support for tagged transactions
 */
module wb_interconnect_tag_NxN #(
		parameter 									ADR_WIDTH=32,
		parameter 									DAT_WIDTH=32,
		parameter									TGC_WIDTH=4,
		parameter									TGA_WIDTH=4,
		parameter									TGD_WIDTH=4,
		parameter 									N_INITIATORS=1,
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
		input[(N_INITIATORS*ADR_WIDTH)-1:0]			adr, 
		input[(N_INITIATORS*DAT_WIDTH)-1:0]			dat_w, 
		output reg[(N_INITIATORS*DAT_WIDTH)-1:0]	dat_r, 
		input[N_INITIATORS-1:0]						cyc, 
		output[N_INITIATORS-1:0]					err, 
		input[N_INITIATORS*(DAT_WIDTH/8)-1:0]		sel, 
		input[N_INITIATORS-1:0]						stb, 
		output reg[N_INITIATORS-1:0]				ack, 
		input[N_INITIATORS-1:0]						we,
		input[N_INITIATORS*TGD_WIDTH-1:0]			tgd_w,
		output reg[N_INITIATORS*TGD_WIDTH-1:0]		tgd_r,
		input[N_INITIATORS*TGA_WIDTH-1:0]			tga,
		input[N_INITIATORS*TGC_WIDTH-1:0]			tgc,
		
		
		// Initiator ports out of the interconnect
		output reg[(N_TARGETS*ADR_WIDTH)-1:0]		tadr,
		output reg[(N_TARGETS*DAT_WIDTH)-1:0]		tdat_w,
		input[(N_TARGETS*DAT_WIDTH)-1:0]			tdat_r,
		output[N_TARGETS-1:0]						tcyc,
		input[N_TARGETS-1:0]						terr,
		output reg[N_TARGETS*(DAT_WIDTH/8)-1:0]		tsel,
		output[N_TARGETS-1:0]						tstb,
		input[N_TARGETS-1:0]						tack,
		output[N_TARGETS-1:0]						twe,
		output reg[N_TARGETS*TGD_WIDTH-1:0]		ttgd_w,
		input[N_TARGETS*TGD_WIDTH-1:0]			ttgd_r,
		output reg[N_TARGETS*TGA_WIDTH-1:0]		ttga,
		output reg[N_TARGETS*TGC_WIDTH-1:0]		ttgc
		);
	
	localparam WB_DATA_MSB = (DAT_WIDTH-1);
	localparam N_INIT_ID_BITS = (N_INITIATORS>1)?$clog2(N_INITIATORS):1;
	localparam N_TARG_ID_BITS = $clog2(N_TARGETS+1);
	localparam NO_TARGET  = {(N_TARG_ID_BITS+1){1'b1}};
	localparam NO_INITIATOR = {(N_INIT_ID_BITS+1){1'b1}};
	
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
					((adr[ADR_WIDTH*md_i+:ADR_WIDTH]&T_ADR_MASK[ADR_WIDTH*md_t_i+:ADR_WIDTH])
						== T_ADR[ADR_WIDTH*md_t_i+:ADR_WIDTH]) && (cyc[md_i] && stb[md_i]);
				assign initiator_target_sel[md_i][md_t_i] = target_initiator_sel[md_t_i][md_i];
			end
		end
	endgenerate

	// Per-target grant vector
	wire[N_INITIATORS-1:0]				initiator_gnt[N_TARGETS-1:0];

	generate
		genvar t_arb_i;
		
		for (t_arb_i=0; t_arb_i<N_TARGETS; t_arb_i=t_arb_i+1) begin : s_arb
			wb_interconnect_arb #(
				.N_REQ  (N_INITIATORS)
				) 
				aw_arb (
					.clock    (clock   ), 
					.reset    (reset  ), 
					// Request vector
					.req    (target_initiator_sel[t_arb_i]),
					// One-hot grant vector
					.gnt    (initiator_gnt[t_arb_i]),
					// signals the end of a transfer
					.ack	(tack[t_arb_i])
					
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
			
	// WB signals from target back to initiator
	generate
		genvar t2i_i, t2i_j;
		integer t2i_ii;
			
		
		for (t2i_i=0; t2i_i<N_INITIATORS; t2i_i=t2i_i+1) begin : block_t2i_i
			always @* begin
				dat_r[DAT_WIDTH*t2i_i+:DAT_WIDTH] = {DAT_WIDTH{1'b0}};
				ack[t2i_i] = 1'b0;
				tgd_r[t2i_i] = {TGD_WIDTH{1'b0}};
				for (t2i_ii=0; t2i_ii<N_TARGETS; t2i_ii=t2i_ii+1) begin
					if (initiator_active_target[t2i_i] == t2i_ii) begin
						dat_r[DAT_WIDTH*t2i_i+:DAT_WIDTH] = 
							tdat_r[DAT_WIDTH*t2i_ii+:DAT_WIDTH];
						// initiator_gnt indicates which initiator the
						// target is currently granted to (one-hot)
						ack[t2i_i] = (initiator_gnt[t2i_ii][t2i_i] && tack[t2i_ii]);
						tgd_r[TGD_WIDTH*t2i_i+:TGD_WIDTH] =
							ttgd_r[TGD_WIDTH*t2i_ii+:TGD_WIDTH];
					end
				end
			end
			assign err[t2i_i] = (initiator_active_target[t2i_i] != NO_TARGET)?
					terr[initiator_active_target[t2i_i]]:1'b0;
		end
	endgenerate

	// Initiator to target mux
	generate
		genvar i2t_mux_i;
		integer i2t_mux_ii;
		for (i2t_mux_i=0; i2t_mux_i<N_TARGETS; i2t_mux_i=i2t_mux_i+1) begin : i2t_mux
			always @* begin
				tadr[ADR_WIDTH*i2t_mux_i+:ADR_WIDTH] = {ADR_WIDTH{1'b0}};
				tdat_w[DAT_WIDTH*i2t_mux_i+:DAT_WIDTH] = {DAT_WIDTH{1'b0}};
				tsel[(DAT_WIDTH/8)*i2t_mux_i+:(DAT_WIDTH/8)] = {(DAT_WIDTH/8){1'b0}};
				ttgd_w[TGD_WIDTH*i2t_mux_i+:TGD_WIDTH] = {TGD_WIDTH{1'b0}};
				ttga[TGA_WIDTH*i2t_mux_i+:TGA_WIDTH] = {TGA_WIDTH{1'b0}};
				ttgc[TGC_WIDTH*i2t_mux_i+:TGC_WIDTH] = {TGC_WIDTH{1'b0}};
				for (i2t_mux_ii=0; i2t_mux_ii<N_INITIATORS; i2t_mux_ii=i2t_mux_ii+1) begin
					if (target_active_initiator[i2t_mux_i] == i2t_mux_ii) begin
						tadr[ADR_WIDTH*i2t_mux_i+:ADR_WIDTH] = 
							adr[ADR_WIDTH*i2t_mux_ii+:ADR_WIDTH];
						tdat_w[DAT_WIDTH*i2t_mux_i+:DAT_WIDTH] = 
							dat_w[DAT_WIDTH*i2t_mux_ii+:DAT_WIDTH];
						tsel[(DAT_WIDTH/8)*i2t_mux_i+:(DAT_WIDTH/8)] = 
							sel[(DAT_WIDTH/8)*i2t_mux_ii+:(DAT_WIDTH/8)];
						ttgd_w[TGD_WIDTH*i2t_mux_i+:TGD_WIDTH] =
								tgd_w[TGD_WIDTH*i2t_mux_ii+:TGD_WIDTH];
						ttga[TGA_WIDTH*i2t_mux_i+:TGA_WIDTH] =
								tga[TGA_WIDTH*i2t_mux_ii+:TGA_WIDTH];
						ttgc[TGC_WIDTH*i2t_mux_i+:TGC_WIDTH] =
								tgc[TGC_WIDTH*i2t_mux_ii+:TGC_WIDTH];
					end
				end
			end
			assign tcyc[i2t_mux_i] = 
				(target_active_initiator[i2t_mux_i] == NO_INITIATOR)?1'b0:
					cyc[target_active_initiator[i2t_mux_i]];
			assign tstb[i2t_mux_i] = 
				(target_active_initiator[i2t_mux_i] == NO_INITIATOR)?1'b0:
					stb[target_active_initiator[i2t_mux_i]];
			assign twe[i2t_mux_i] = 
				(target_active_initiator[i2t_mux_i] == NO_INITIATOR)?1'b0:
					we[target_active_initiator[i2t_mux_i]];
		end
	endgenerate
	
	// Instance debug interface point
	initial begin
		$display("Note: N_INITIATORS=%0d N_TARGETS=%0d clog2(INIT)=%0d",
				N_INITIATORS, N_TARGETS, $clog2(N_INITIATORS));
	end
	wire [($clog2(N_INITIATORS)*N_TARGETS)-1:0] target_initiator;

	generate
		genvar target_initiator_i;
		for (target_initiator_i=0; target_initiator_i<N_TARGETS; target_initiator_i=target_initiator_i+1) begin : target_initiator_assign
			assign target_initiator[target_initiator_i*$clog2(N_INITIATORS)+:$clog2(N_INITIATORS)] 
				= target_active_initiator[target_initiator_i];
		end
	endgenerate
	
	wb_interconnect_tag_NxN_dbg #(
		.ADR_WIDTH         (ADR_WIDTH        ), 
		.DAT_WIDTH         (DAT_WIDTH        ), 
		.TGC_WIDTH         (TGC_WIDTH        ), 
		.TGA_WIDTH         (TGA_WIDTH        ), 
		.TGD_WIDTH         (TGD_WIDTH        ), 
		.N_INITIATORS      (N_INITIATORS     ), 
		.N_TARGETS         (N_TARGETS        ), 
		.T_ADR_MASK        (T_ADR_MASK       ), 
		.T_ADR             (T_ADR            )
		) u_dbg (
		.clock             (clock            ), 
		.reset             (reset            ), 
		.i_adr             (adr             ), 
		.i_dat_w           (dat_w           ), 
		.i_dat_r           (dat_r           ), 
		.i_cyc             (cyc             ), 
		.i_err             (err             ), 
		.i_sel             (sel             ), 
		.i_stb             (stb             ), 
		.i_ack             (ack             ), 
		.i_we              (we              ), 
		.i_tgd_w           (tgd_w           ), 
		.i_tgd_r           (tgd_r           ), 
		.i_tga             (tga             ), 
		.i_tgc             (tgc             ), 
		.t_adr             (tadr            ), 
		.t_dat_w           (tdat_w          ), 
		.t_dat_r           (tdat_r          ), 
		.t_cyc             (tcyc            ), 
		.t_err             (terr            ), 
		.t_sel             (tsel            ), 
		.t_stb             (tstb            ), 
		.t_ack             (tack            ), 
		.t_we              (twe             ), 
		.t_tgd_w           (ttgd_w          ), 
		.t_tgd_r           (ttgd_r          ), 
		.t_tga             (ttga            ), 
		.t_tgc             (ttgc            ), 
		.target_initiator  (target_initiator ));
	
//	// Error target
//	reg err_req;
//	always @(posedge clock) begin
//		if (reset == 1) begin
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

