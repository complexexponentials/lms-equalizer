//                              -*- Mode: Verilog -*-
// Filename        : fir_channel
// Description     : FIR Channel
// Author          : Ariel Pola
// Created On      : 
// Last Modified By: .
// Last Modified On: .
// Update Count    : 0
// Status          : Unknown, Use with caution!

 //`include "../include/ffe_dffe_parameters.v"

module fir_channel
  (
   i_fir_channel_bits,
   o_dot_product_ch,
   prmt_coeff_channel,
   clock
   );
   
   
   (* USE_DSP48="YES" *)
      
   ///////////////////////////////////////////
   // Parameter
   /////////////////////////////////////////// 
//   parameter PARALLELISM           = `PARALLELISM;
   parameter NUM_COEFF_CH          = `NUM_COEFF_CH;
   parameter NBI_COEFF_CH          = `NBI_COEFF_CH;
   parameter NBF_COEFF_CH          = `NBF_COEFF_CH;
   parameter NB_LOG2_COEFF_CH      = `NB_LOG2_COEFF_CH;

   
   ///////////////////////////////////////////
   // Localparam
   ///////////////////////////////////////////
   localparam NB_COEFF_CH          = NBI_COEFF_CH + NBF_COEFF_CH;

   localparam NBI_DOT_COEFF        = NBI_COEFF_CH + NB_LOG2_COEFF_CH;
   localparam NBF_DOT_COEFF        = NBF_COEFF_CH;
   localparam NB_DOT_COEFF         = NBI_DOT_COEFF + NBF_DOT_COEFF;

   
   ///////////////////////////////////////////
   // Port
   ///////////////////////////////////////////
   output reg [NB_DOT_COEFF             - 1 : 0] o_dot_product_ch;
   
   input wire                                    i_fir_channel_bits;
   
   input wire [NUM_COEFF_CH*NB_COEFF_CH - 1 : 0] prmt_coeff_channel;

   input wire                                    clock;
   ///////////////////////////////////////////
   // Vars
   ///////////////////////////////////////////

   reg [NUM_COEFF_CH             - 1 : 0]        channel_bits;

   reg [NUM_COEFF_CH*NB_COEFF_CH  - 1 : 0]       coeff_channel_d;
   wire signed [NB_COEFF_CH       - 1 : 0]       coeff_channel[NUM_COEFF_CH - 1 : 0];
   wire signed [NB_COEFF_CH       - 1 : 0]       dot_filter[NUM_COEFF_CH - 1 : 0];
   
   reg signed [NB_DOT_COEFF       - 1 : 0]       add_dot_filter;
   reg signed [NB_DOT_COEFF       - 1 : 0]       dot_filter_exp;

 
   integer                                       ptr_add;
   
   always@(posedge clock) begin
      coeff_channel_d  <= prmt_coeff_channel;
      o_dot_product_ch <= add_dot_filter;
      channel_bits     <= {{channel_bits[NUM_COEFF_CH-2 -: NUM_COEFF_CH-1]},i_fir_channel_bits};
      
   end
   
   
   
   generate
      genvar                                     ptr;
      for(ptr=0;ptr<NUM_COEFF_CH;ptr=ptr+1) begin:dotprod
         assign coeff_channel[ptr]  = coeff_channel_d[((ptr+1)*NB_COEFF_CH)-1 -: NB_COEFF_CH];
         assign dot_filter[ptr]     = (channel_bits[ptr] == 1'b0)                            ? coeff_channel[ptr] :
                                      (coeff_channel[ptr] == {{1'b1},{NB_COEFF_CH-1{1'b0}}}) ? {{1'b0},{NB_COEFF_CH-1{1'b1}}} :
                                      -coeff_channel[ptr];
      end
   endgenerate

   always@(*) begin:convfilter
      add_dot_filter = {NB_DOT_COEFF{1'b0}};
      for(ptr_add=0;ptr_add<NUM_COEFF_CH;ptr_add=ptr_add+1) begin:convpartial
         dot_filter_exp = {{NBI_DOT_COEFF-NBI_COEFF_CH{dot_filter[ptr_add][NB_COEFF_CH-1]}},dot_filter[ptr_add]};
         add_dot_filter = add_dot_filter + dot_filter_exp;
      end
   end

   


         
endmodule // fir_channel
