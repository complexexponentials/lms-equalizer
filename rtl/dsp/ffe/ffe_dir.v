`timescale 1ns / 1ps

module ffe_dir#(
    parameter DATA_BW = 11, // Data bit width
    parameter OUT_BW = 9,   // Ouput bit width
    parameter COEF_BW = 9,  // Coefficients bit width
    parameter N_COEF = 7    // Number of coefficients
    )
    (
    input                        i_clk,
    input                        i_rst,
    input                        i_en,
    input signed [DATA_BW-1:0]   i_data,
    output signed [OUT_BW-1:0]   o_data,

    input [(COEF_BW*N_COEF)-1:0] i_coefs   // Coefficients bus: CN, CN-1, ... , C1, C0
    );

    reg signed  [DATA_BW-1:0]   data_dl [0:N_COEF-1];
    wire signed [COEF_BW-1:0]   coefs   [0:N_COEF-1];
    wire signed [19:0]          prods   [0:N_COEF-1];
    wire signed [22:0]          dout_int;
    wire signed [20:0]          sums_l1[0:3];
    wire signed [21:0]          sums_l2[0:1];

    integer i;  // Iterator
    genvar  k;  // Generation variable

    /* Input delay line */
    always @(i_data) data_dl[0] = i_data;
    always @(posedge i_clk) begin
        if(i_rst) begin
            for (i=0; i<(N_COEF-1); i=i+1)
                data_dl[i+1] <= 0;
        end
        else if(i_en) begin
            for (i=0; i<(N_COEF-1); i=i+1)
                data_dl[i+1] <= data_dl[i];
        end
    end

    /* Bus unpacking */
    generate
        for (k=0; k<N_COEF; k=k+1) begin
            assign coefs[k] = i_coefs[COEF_BW*(k+1)-1:COEF_BW*k];
        end
    endgenerate

    /* Products */
    generate
        for (k=0; k<N_COEF; k=k+1)
            assign prods[k] = coefs[k] * data_dl[k];
    endgenerate

    generate
        for (k=0; k<(N_COEF/2); k=k+1)
            assign sums_l1[k] = prods[(2*k)]+prods[(2*k)+1];
    endgenerate

    assign sums_l2[0] = sums_l1[0] + sums_l1[1];
    assign sums_l2[1] = sums_l1[2] + {prods[6][19],prods[6]};

    assign dout_int = sums_l2[0] + sums_l2[1];
    assign o_data = dout_int[15:15-(OUT_BW-1)]; //8:0

// `ifdef COCOTB_SIM
//    initial begin
//       $dumpfile("./sim_build/ffe_dir.vcd");
//       $dumpvars(0, prods[0], prods[1], prods[2], prods[3], prods[4], prods[5], prods[6]);
//       $dumpvars(0, sums_l1[0], sums_l1[1], sums_l1[2]);
//       $dumpvars(0, sums_l2[0], sums_l2[1]);
//       $dumpvars(0, ffe_dir);
//    end
// `endif

endmodule
