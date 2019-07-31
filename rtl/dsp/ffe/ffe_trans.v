`timescale 1ns / 1ps

module ffe_trans
  #(
    parameter DATA_BW = 11,  // Data bit width
    parameter COEF_BW = 9,   // Coefficients bit width
    parameter N_COEF = 7     // Number of coefficients
    )
  (
   input                        i_clk,
   input                        i_rst,
   input                        i_en,
   input signed [DATA_BW-1:0]   i_data,
   output signed [COEF_BW-1:0]  o_data,

   input [(COEF_BW*N_COEF)-1:0] i_coefs   // Coefficients bus: CN, CN-1, ... , C1, C0
   );

   wire signed [COEF_BW-1:0]    coefs [0:N_COEF];
   wire signed [19:0]           prods [6:0];
   //wire signed [11:0]           prods_cut [0:6];
   reg signed [22:0]            sum_reg  [6:0]; // [11:0]
   wire signed [23:0]           sum_next [6:0]; // MSB descartado [12:0]
   wire signed [22:0]           dout_int; // MSB descartado [12:0]

   integer                      i;
   
   genvar   k;
   generate
      for (k=0; k<N_COEF; k = k+1) begin
        assign coefs[k] = i_coefs[COEF_BW*(k+1)-1:COEF_BW*k];
      end
   endgenerate

   generate
      for (k=0; k<N_COEF; k = k+1)
        assign prods[k] = coefs[k] * i_data;
   endgenerate

  //  generate
  //     for (k=0; k<N_COEF; k = k+1)
  //       assign prods_cut[k] = {{3{prods[k][19]}}, prods[k][17:9]};
  //  endgenerate

   always @(posedge i_clk) begin
      if(i_rst) begin
         for(i=0; i<N_COEF; i = i + 1)
           sum_reg[i] <= 0;
      end
      else begin
         if (i_en)
           for(i=0; i<N_COEF; i = i + 1)
             sum_reg[i] <= sum_next[i][22:0];
      end
   end

   assign sum_next[6] = {{4{prods[6][19]}},prods[6]};
   generate
      for(k=0; k<6; k = k + 1)
        assign sum_next[k] = prods[k] + sum_reg[k + 1];
   endgenerate

   //assign dout_int = prods_cut[0] + sum_reg[0];
   assign o_data = sum_next[0][15:7]; //8:0

endmodule
