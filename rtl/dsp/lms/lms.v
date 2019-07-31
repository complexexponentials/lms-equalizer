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
    input signed [7:0] i_error,
    input signed [7:0] i_mu,
    
    output [(COEF_BW*N_COEF)-1:0] o_coefs
);

reg signed [8:0]data_dl [0:6];   // S(9,7) Input data delay line

reg signed [8:0]coef0_dl [0:6];   // S(9,7) Coefficient 0 delay line
reg signed [8:0]coef1_dl [0:5];   // S(9,7) Coefficient 1 delay line
reg signed [8:0]coef2_dl [0:4];   // S(9,7) Coefficient 2 delay line
reg signed [8:0]coef3_dl [0:3];   // S(9,7) Coefficient 3 delay line
reg signed [8:0]coef4_dl [0:2];   // S(9,7) Coefficient 4 delay line
reg signed [8:0]coef5_dl [0:1];   // S(9,7) Coefficient 5 reg

wire signed [25:0]c_next [0:6];  // S(26,21)
reg signed [24:0]c_reg  [0:6];  // S(25,21)

wire signed [15:0]error_weightened;    // S(16,14)
wire signed [24:0]correction_term  [0:6];    // S(25,21) : Mu.e(n).x(n-i)

integer i;  // Iterator

localparam T = 22;

// Input delay line
always @(i_data) data_dl[0] = i_data;
always @(posedge i_clk) begin
    if(i_rst) begin
        for (i=0; i<6; i=i+1)
            data_dl[i+1] <= 0;
    end
    else if(i_en) begin
        for (i=0; i<6; i=i+1)
            data_dl[i+1] <= data_dl[i];
    end
end

assign error_weightened = i_error * i_mu;

genvar k;
generate
    for (k=0; k<7; k=k+1)
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
            for (i=0; i<7; i=i+1)
                c_reg[i] <= c_next[i][24:0];
end

generate
    for (k=0; k<7; k=k+1)
        assign c_next[k] = c_reg[k] + correction_term[k];
endgenerate


// Coefs delay line coef0:6d - coef1:5d - coef2:4d - coef3:3d - coef4:2d - coef5:1d
// Due to filter transposed form:


// Coefficient 5: 1 delay
always @(c_reg[1]) coef5_dl[0] = c_reg[1][T:T-8];
always @(posedge i_clk) begin
    if(i_rst) begin
        coef5_dl[1] <= 0;
    end
    else begin
        coef5_dl[1] <= coef5_dl[0];
    end
end

// Coefficient 4: 2 delays
always @(c_reg[2]) coef4_dl[0] = c_reg[2][T:T-8];
always @(posedge i_clk) begin
    if(i_rst) begin
        for (i=0; i<2; i=i+1)
            coef4_dl[i+1] <= 0;
    end
    else begin
        for (i=0; i<2; i=i+1)
            coef4_dl[i+1] <= coef4_dl[i];
    end
end

// Coefficient 3: 3 delays
always @(c_reg[3]) coef3_dl[0] = c_reg[3][T:T-8];
always @(posedge i_clk) begin
    if(i_rst) begin
        for (i=0; i<3; i=i+1)
            coef3_dl[i+1] <= 9'b0_1000_0000;
    end
    else begin
        for (i=0; i<3; i=i+1)
            coef3_dl[i+1] <= coef3_dl[i];
    end
end

// Coefficient 2: 4 delays
always @(c_reg[4]) coef2_dl[0] = c_reg[4][T:T-8];
always @(posedge i_clk) begin
    if(i_rst) begin
        for (i=0; i<4; i=i+1)
            coef2_dl[i+1] <= 0;
    end
    else begin
        for (i=0; i<4; i=i+1)
            coef2_dl[i+1] <= coef2_dl[i];
    end
end

// Coefficient 1: 5 delays
always @(c_reg[5]) coef1_dl[0] = c_reg[5][T:T-8];
always @(posedge i_clk) begin
    if(i_rst) begin
        for (i=0; i<5; i=i+1)
            coef1_dl[i+1] <= 0;
    end
    else begin
        for (i=0; i<5; i=i+1)
            coef1_dl[i+1] <= coef1_dl[i];
    end
end

// Coefficient 0: 6 delays
always @(c_reg[6]) coef0_dl[0] = c_reg[6][T:T-8];
always @(posedge i_clk) begin
    if(i_rst) begin
        for (i=0; i<6; i=i+1)
            coef0_dl[i+1] <= 0;
    end
    else begin
        for (i=0; i<6; i=i+1)
            coef0_dl[i+1] <= coef0_dl[i];
    end
end

// // Coefficient 7 goes directly
// assign o_coefs[(COEF_BW*N_COEF)-1:COEF_BW*(N_COEF-1)] = c_reg[6][T:T-8];
// assign o_coefs[COEF_BW*6-1:COEF_BW*5] = coef5_dl[1];
// assign o_coefs[COEF_BW*5-1:COEF_BW*4] = coef4_dl[2];
// assign o_coefs[COEF_BW*4-1:COEF_BW*3] = coef3_dl[3];
// assign o_coefs[COEF_BW*3-1:COEF_BW*2] = coef2_dl[4];
// assign o_coefs[COEF_BW*2-1:COEF_BW] = coef1_dl[5];
// assign o_coefs[COEF_BW-1:0] = coef0_dl[6];

assign o_coefs[(COEF_BW*N_COEF)-1:COEF_BW*(N_COEF-1)] = c_reg[6][T:T-8];//coef0_dl[6];
assign o_coefs[COEF_BW*6-1:COEF_BW*5] = c_reg[5][T:T-8];//coef1_dl[5];
assign o_coefs[COEF_BW*5-1:COEF_BW*4] = c_reg[4][T:T-8];//coef2_dl[4];
assign o_coefs[COEF_BW*4-1:COEF_BW*3] = c_reg[3][T:T-8];//coef3_dl[3];
assign o_coefs[COEF_BW*3-1:COEF_BW*2] = c_reg[2][T:T-8];//coef4_dl[2];
assign o_coefs[COEF_BW*2-1:COEF_BW] = c_reg[1][T:T-8];//coef5_dl[1];
assign o_coefs[COEF_BW-1:0] = c_reg[0][T:T-8];

// `ifdef COCOTB_SIM
//      initial begin
//          $dumpfile("./sim_build/lms.vcd");
//          $dumpvars(0,lms);
//          $dumpvars(0, correction_term[0],correction_term[1],correction_term[2],
//          correction_term[3],correction_term[4],correction_term[5],correction_term[6],
//          c_reg[0],c_reg[1],c_reg[2],c_reg[3],c_reg[4],c_reg[5],c_reg[6],
//          c_next[0],c_next[1],c_next[2],c_next[3],c_next[4],c_next[5],c_next[6],
//          coef0_dl[0],coef0_dl[1],coef0_dl[2],coef0_dl[3],coef0_dl[4],coef0_dl[5],
//          coef1_dl[0],coef1_dl[1],coef1_dl[2],coef1_dl[3],coef1_dl[4],
//          coef2_dl[0],coef2_dl[1],coef2_dl[2],coef2_dl[3],
//          coef3_dl[0],coef3_dl[1],coef3_dl[2],
//          coef4_dl[0],coef4_dl[1]);

//      end
// `endif

endmodule
