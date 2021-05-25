/****************************************************************************
 * wb_interconnect_2x2_tb.sv
 ****************************************************************************/
`ifdef NEED_TIMESCALE
`timescale 1ns/1ns
`endif
 `include "wishbone_macros.svh"
 
 module initiator #(
 		parameter N_TARGETS=1,
 		parameter ID=0
		) (
 		input clock,
 		input reset,
 		`WB_INITIATOR_PORT(i_, 16, 32)
 		);
 	
 	reg [1:0]	state = 0;
 	wire		next_we;
 	reg			we_r = 0;
 	wire[3:0] 	next_target;
 	reg[15:0]	adr_r = 0;
 	reg			cyc_r = 0;
 	wire[3:0]	tgt_id = ID;
 	wire[15:0]	next_dat_w;
 	reg[15:0]	dat_w_r;
 	reg[3:0]	count;
 	
 	assign i_cyc 	= cyc_r;
 	assign i_stb 	= cyc_r;
 	assign i_adr 	= adr_r;
 	assign i_we  	= we_r;
 	assign i_dat_w 	= dat_w_r;
 	
 	always @(posedge clock or posedge reset) begin
 		if (reset) begin
 			state <= 0;
 			we_r <= 1'b0;
 			adr_r <= {16{1'b0}};
 			cyc_r <= 1'b0;
 			count <= 0;
 		end else begin
 			case (state)
 				0: begin
 					we_r <= next_we;
 					adr_r[15:12] <= (next_target & 1);
 					adr_r[11:8] <= tgt_id;
 					adr_r[7:0] <= count;
 					count <= count + 1;
 					cyc_r <= 1'b1;
 					dat_w_r <= next_dat_w;
 					we_r <= next_we;
 					state <= 1;
 					
 					// Can't have an ack until we issue a cycle
 					assert(i_ack == 0);
 				end
 				1: begin
 					// Never expect a single-cycle turn-around
 					assert(~i_ack);
 					state <= 2;
 				end
 				2: begin
 					if (i_ack) begin
 						state <= 0;
 						cyc_r <= 1'b0;
 					end
 				end
 			endcase
 		end
 	end
 endmodule
 
 module target(
 		input			clock,
 		input			reset,
 		`WB_TARGET_PORT(t_, 16, 16)
 		);
 	
 	reg [1:0] 	state;
 	wire[15:0]	next_dat_r;
 	reg			ack_r;
 	reg[15:0]	dat_r_r;
 	
 	assign t_dat_r = dat_r_r;
 	assign t_ack = ack_r;
 	
 	always @(posedge clock or posedge reset) begin
 		if (reset) begin
 			state <= 0;
 			ack_r <= 1'b0;
 			dat_r_r <= {16{1'b0}};
 		end else begin
 			case (state)
 				0: begin
 					if (t_cyc && t_stb) begin
 						dat_r_r <= next_dat_r;
 						state <= 1;
 						ack_r <= 1'b1;
 					end
 				end
 				
 				1: begin
 					ack_r <= 1'b0;
 					state <= 0;
 				end
 				
 				2: begin
 					ack_r <= 1'b0;
 					state <= 0;
 				end
 			endcase
 		end 
 	end
 endmodule
 

/**
 * Module: wb_interconnect_2x2_tb
 * 
 * TODO: Add module documentation
 */
module wb_interconnect_2x2_tb(input clock);

	reg  init = 1;
	reg  reset = 1;
	
`ifdef IVERILOG
	reg clock_r = 0;
	initial begin
		forever begin
			#10;
			clock_r <= ~clock_r;
		end
	end
	assign clock = clock_r;
`endif
	
	always @(posedge clock) begin
		reset <= 0;
		/*
		if (init) begin
			assume(reset);
		end else begin
			assume(~reset);
		end
		init <= 0;
		 */
	end
	
	`WB_WIRES_ARR(i2ic_, 16, 16, 2);
	`WB_WIRES_ARR(ic2t_, 16, 16, 2);
	
	generate
		genvar init_i;
		for (init_i=0; init_i<2; init_i=init_i+1) begin : initiator
			initiator #(
				.N_TARGETS  (2 ), 
				.ID         (init_i    )
				) u_init (
				.clock      (clock     ), 
				.reset      (reset     ), 
				`WB_CONNECT_ARR(i_, i2ic_, init_i, 16, 16));
		end
	endgenerate

	wb_interconnect_NxN #(
		.WB_ADDR_WIDTH  (16 ), 
		.WB_DATA_WIDTH  (16 ), 
		.N_INITIATORS   (2  ), 
		.N_TARGETS      (2  ), 
		.T_ADR_MASK     ({
			16'hF000,
			16'hF000
			}), 
		.T_ADR          ({
			16'h0000,
			16'h1000
			})
		) u_dut (
		.clock          (clock         ), 
		.reset          (reset         ), 
		`WB_CONNECT( , i2ic_),
		`WB_CONNECT(t, ic2t_));

	reg[3:0] count;
	integer i, j;
	always @(posedge clock or posedge reset) begin
		if (reset) begin
			count <= 0;
		end else begin
			
			// Ensure that ACK is never asserted for 
			// two initiators targeting the same device
			// at the same time
			for (i=0; i<2; i=i+1) begin
				if (i2ic_cyc[i] && i2ic_ack[i]) begin
					count <= count + 1;
				end
				cover(count == 10);
				for (j=i+1; j<2; j=j+1) begin
					if (i2ic_cyc[i] && i2ic_cyc[j]) begin
//						assert(~i2ic_ack[i] || ~i2ic_ack[j]);
//						assert(0);
//						assume(i2ic_adr[31:28] == i2ic_adr[15:12]);
//						assume(i2ic_cyc[i] && i2ic_cyc[j]);
						if (i2ic_adr[31:28] == i2ic_adr[15:12]) begin
//						if (i2ic_adr[((16*i)+11)+:4] == ic2ic_adr[((16*j)+11)+:4]) begin
							assert(~i2ic_ack[i] || ~i2ic_ack[j]);
						end
					end
				end
			end
		end
	end
	
	generate
		genvar targ_i;
		for (targ_i=0; targ_i<2; targ_i=targ_i+1) begin : target
			target u_targ (
				.clock    (clock   ), 
				.reset    (reset   ), 
				`WB_CONNECT_ARR(t_, ic2t_, targ_i, 16, 16));
		end
	endgenerate

endmodule


