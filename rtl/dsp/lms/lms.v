`timescale 1ns / 1ps 

module lms #(
    parameter DATA_BW = 11,  // Data bit width
    parameter COEF_BW = 9,   // Coefficients bit width
    parameter N_COEF = 7     // Number of coefficients
)
(
    input i_clk,
    input i_rst,
    input signed [DATA_BW-1:0] i_data,
    input i_en,
    input signed [7:0] i_error, //S(8,7)
    input signed [7:0] i_mu,    //S(8,7)
    
    output [(COEF_BW*N_COEF)-1:0] o_coefs
);

reg signed [8:0]data_dl [0:N_COEF-1];   // S(9,7) Input data delay line

wire signed [15:0]error_weightened;    // S(16,14)
wire signed [24:0]correction_term  [0:N_COEF-1];    // S(25,21) : Mu.e(n).x(n-i)

wire signed [25:0]c_next [0:N_COEF-1];  // S(26,21)
reg signed [24:0]c_reg  [0:N_COEF-1];  // S(25,21)

integer i;  // Iterator

// Input delay line
always @(i_data) data_dl[0] = i_data;
always @(posedge i_clk) begin
    if(i_rst) begin
        for (i=0; i<N_COEF-1; i=i+1)
            data_dl[i+1] <= 0;
    end
    else if(i_en) begin
        for (i=0; i<N_COEF-1; i=i+1)
            data_dl[i+1] <= data_dl[i];
    end
end

assign error_weightened = i_error * i_mu;

genvar k;
generate
    for (k=0; k<N_COEF; k=k+1)
        assign correction_term[k] = error_weightened * data_dl[k];
endgenerate

always @(posedge i_clk) begin
    if (i_rst) begin
        c_reg[0] <= 0;
        c_reg[1] <= 0;
        c_reg[2] <= 0;
        c_reg[3] <= 25'b0_0010_0000_0000_0000_0000_0000; // 1 en S(25,21)
        c_reg[4] <= 0;
        c_reg[5] <= 0;
        c_reg[6] <= 0;
    end
    else
        if (i_en)
            for (i=0; i<N_COEF; i=i+1)
                c_reg[i] <= c_next[i][24:0];
end

generate
    for (k=0; k<N_COEF; k=k+1)
        assign c_next[k] = c_reg[k] + correction_term[k];
endgenerate

localparam T = 22;

/* Truncado y saturación de S(25,21) a S(9,7) 
   T es el bit que se tomará como el más significativo */

generate
    for (k=0; k<N_COEF; k=k+1)
        assign o_coefs[COEF_BW*(k+1)-1:COEF_BW*k] = {c_reg[k][24],c_reg[k][T-1:T-8]};
endgenerate


endmodule
