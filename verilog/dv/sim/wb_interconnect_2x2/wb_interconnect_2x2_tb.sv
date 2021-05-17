/****************************************************************************
 * wb_interconnect_2x2_tb.sv
 ****************************************************************************/
`ifdef NEED_TIMESCALE
	`timescale 1ns/1ns
`endif

`include "wishbone_macros.svh"
  
/**
 * Module: wb_interconnect_2x2_tb
 * 
 * TODO: Add module documentation
 */
module wb_interconnect_2x2_tb(input clock);
	
`ifdef HAVE_HDL_CLOCKGEN
	reg clock_r = 0;
	initial begin
		forever begin
`ifdef NEED_TIMESCALE
			#10;
`else
			#10ns;
`endif
			clock_r <= ~clock_r;
		end
	end
	assign clock = clock_r;
`endif
	
	reg reset = 0;
	reg[7:0] reset_cnt = 0;
	
	always @(posedge clock) begin
		case (reset_cnt)
			2: begin
				reset <= 1;
				reset_cnt <= reset_cnt + 1;
			end
			20: begin
				reset <= 0;
			end
			default: reset_cnt <= reset_cnt + 1;
		endcase
	end
	
`ifdef IVERILOG
	`include "iverilog_control.svh"
`endif
	
	localparam N_INITIATORS = 2;
	localparam N_TARGETS = 2;
	
	`WB_WIRES_ARR(bfm2ic_, 32, 32, N_INITIATORS);
	`WB_WIRES_ARR(ic2bfm_, 32, 32, N_TARGETS);

	generate
		genvar initiator_bfm_i;
		for (initiator_bfm_i=0; initiator_bfm_i<N_INITIATORS; initiator_bfm_i=initiator_bfm_i+1) begin : initiator
			wb_initiator_bfm #(
				.ADDR_WIDTH  (32 ),
				.DATA_WIDTH  (32 )
			) u_initiator_bfm (
				.clock       (clock      ), 
				.reset       (reset      ), 
				`WB_CONNECT_ARR( , bfm2ic_, initiator_bfm_i, 32, 32));
		end
	endgenerate
	
	wb_interconnect_NxN #(
		.WB_ADDR_WIDTH  (32 ), 
		.WB_DATA_WIDTH  (32 ), 
		.N_INITIATORS   (N_INITIATORS  ), 
		.N_TARGETS      (N_TARGETS     ), 
		.T_ADR_MASK     ({
				32'hF000_0000,
				32'hF000_0000/*,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000,
				32'hF000_0000
				 */
			}),
		.T_ADR          ({
				32'h0000_0000, // Target N-1
				32'h1000_0000/*, 
				32'h2000_0000, 
				32'h3000_0000,
				32'h4000_0000,
				32'h5000_0000,
				32'h6000_0000,
				32'h7000_0000,
				32'h8000_0000,
				32'h9000_0000,
				32'hA000_0000,
				32'hB000_0000,
				32'hC000_0000,
				32'hD000_0000,
				32'hE000_0000, // Target 1
				32'hF000_0000  // Target 0
				*/
			})
		) u_dut (
			.clock          (clock         ), 
			.reset          (reset         ), 
			`WB_CONNECT( , bfm2ic_),
			`WB_CONNECT(t, ic2bfm_)
		);

	generate
		genvar target_bfm_i;
		for (target_bfm_i=0; target_bfm_i<N_TARGETS; target_bfm_i=target_bfm_i+1) begin : target
			wb_target_bfm #(
				.ADDR_WIDTH  (32 ), 
				.DATA_WIDTH  (32 )
				) u_target_bfm (
				.clock       (clock      ), 
				.reset       (reset      ), 
				`WB_CONNECT_ARR( , ic2bfm_, target_bfm_i, 32, 32));
		end
	endgenerate
	
endmodule


