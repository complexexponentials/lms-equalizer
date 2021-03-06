`timescale 1ns / 1ps

module ffe_dir#(
    parameter IN_BW = 11,   // Input bit width
    parameter OUT_BW = 9,   // Output bit width
    parameter COEF_BW = 9,  // Coefficients bit width
    parameter N_COEF = 7    // Number of coefficients
    )
    (
    input                        i_clk,
    input                        i_rst,
    input                        i_en,
    input signed     [IN_BW-1:0]    i_data,
    output reg signed[OUT_BW-1:0]   o_data,

    input [(COEF_BW*N_COEF)-1:0] i_coefs   // Coefficients bus: CN, CN-1, ... , C1, C0
    );

    localparam OUT_MSb = 15;    // Ouput MSb for truncation and saturation

    reg signed  [IN_BW-1:0]     data_dl [0:N_COEF-1];
    wire signed [COEF_BW-1:0]   coefs   [0:N_COEF-1];
    wire signed [19:0]          prods   [0:N_COEF-1]; // S(20,14)
    reg signed [20:0]          sums_l1[0:3]; // level 1 sum
    wire signed [21:0]          sums_l2[0:1]; // level 2 sum
    wire signed [22:0]          dout_int;

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

    /* Adder tree */
    // Pipeline:
    always@(posedge i_clk) begin
        for (i=0; i<(N_COEF/2); i=i+1)
            sums_l1[i] <= prods[(2*i)]+prods[(2*i)+1];
    end

    assign sums_l2[0] = sums_l1[0] + sums_l1[1];
    assign sums_l2[1] = sums_l1[2] + prods[6];

    assign dout_int = sums_l2[0] + sums_l2[1];  //S(23,14)

    always@(posedge i_clk)
        truncate_and_saturate(dout_int, o_data);

    task truncate_and_saturate;
        input signed    [22:0]full_prec;
        output signed   [OUT_BW-1:0] red_prec;
        begin
            if (( (&full_prec[22:OUT_MSb]) | (~|full_prec[22:OUT_MSb])))
                red_prec = full_prec[OUT_MSb:OUT_MSb-OUT_BW+1];
            else if (full_prec[22])
                red_prec = {1'b1,{(OUT_BW-1){1'b0}}};
            else
                red_prec = {1'b0,{(OUT_BW-1){1'b1}}};
        end
    endtask

endmodule
