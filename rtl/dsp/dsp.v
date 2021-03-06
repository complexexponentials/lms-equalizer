`timescale 1ns / 1ps 

module dsp
(
    input clockdsp,
    input soft_reset,
    input [3:0]rf_enables_module,
    input [10:0]connect_ch_to_dsp,
    input [7:0]step_mu,
    
    // Logger
    input   log_in_ram_run_from_micro,
    input   [14:0] log_read_addr_from_micro,
    output  log_out_full_from_ram,
    output  [31:0]log_data_from_ram
);

localparam COEF_BW = 9;
localparam N_COEF = 7;
localparam FIR_PIPE_STAGES = 2;

integer i;  // Iterator

wire signed [8:0] ffe_out;

wire [(COEF_BW*N_COEF)-1:0] coefs;

wire signed [8:0] slice;
wire signed [9:0] error;            // MSbs discared

reg [10:0]connect_ch_to_dsp_dl [FIR_PIPE_STAGES:0];     // Input data delay line

reg [7:0]step_mu_reg;

// Register for external input
always @(posedge clockdsp) begin
    if (soft_reset)
        step_mu_reg <= 0;
    else
        step_mu_reg <= step_mu;
end

ffe_dir #(
    .IN_BW      (11),       // Data bit width
    .OUT_BW     (COEF_BW),  // Ouput bit width
    .COEF_BW    (COEF_BW),  // Coefficients bit width
    .N_COEF     (N_COEF)    // Number of coefficients
)
ffe_inst(
    .i_clk      (clockdsp),
    .i_rst      (soft_reset),
    .i_en       (rf_enables_module[0]),
    .i_data     (connect_ch_to_dsp),
    .o_data     (ffe_out),   // 2 Pipeline stages
    .i_coefs    (coefs)
);

assign slice = ffe_out[8] ? 9'b110000000 : 9'b010000000; // S(9,7) : 1,-1
assign error = slice - ffe_out;

// Pipeline for input (to keep aligned with error)
always@(connect_ch_to_dsp) connect_ch_to_dsp_dl[0] = connect_ch_to_dsp;
always@(posedge clockdsp) begin
    if (soft_reset)
        for(i=0; i<FIR_PIPE_STAGES; i=i+1)
            connect_ch_to_dsp_dl[i] <= 0;
    else
        for(i=0; i<FIR_PIPE_STAGES; i=i+1)
            connect_ch_to_dsp_dl[i+1] <= connect_ch_to_dsp_dl[i];
end

lms #(
    .DATA_BW    (11),        // Data bit width
    .COEF_BW    (COEF_BW),   // Coefficients bit width
    .N_COEF     (N_COEF)     // Number of coefficients
)
lms_inst(
    .i_clk      (clockdsp),
    .i_rst      (soft_reset),
    .i_data     (connect_ch_to_dsp_dl[FIR_PIPE_STAGES]),
    .i_en       (rf_enables_module[0]),
    .i_error    (error[7:0]), // S(8,7) always < 1
    .i_mu       (step_mu_reg),
    .o_coefs    (coefs)
);


bram bram_inst
(
    .clockdsp                   (clockdsp),
    .soft_reset                 (soft_reset),
    .log_in_ram_run_from_micro  (log_in_ram_run_from_micro),
    .log_read_addr_from_micro   (log_read_addr_from_micro),
    .log_input_select           (rf_enables_module[3:1]),
    .log_out_full_from_ram      (log_out_full_from_ram),
    .log_data_from_ram          (log_data_from_ram),
    // Log inputs
    .log_in_1   (connect_ch_to_dsp),
    .log_in_2   (ffe_out),
    .log_in_3   (error[7:0]),
    .log_in_4   (coefs)
);


`ifdef COCOTB_SIM
    initial begin
        $dumpfile("./sim_build/dsp.vcd");
        $dumpvars(0, ffe_inst.coefs[0], ffe_inst.coefs[1], ffe_inst.coefs[2],ffe_inst.coefs[3],
                  ffe_inst.coefs[4], ffe_inst.coefs[5], ffe_inst.coefs[6]);        
        $dumpvars(0, lms_inst.c_reg[0], lms_inst.c_reg[1], lms_inst.c_reg[2],lms_inst.c_reg[3],
                  lms_inst.c_reg[4], lms_inst.c_reg[5], lms_inst.c_reg[6]);
        $dumpvars(0, lms_inst.c_next[0], lms_inst.c_next[1], lms_inst.c_next[2],lms_inst.c_next[3],
                  lms_inst.c_next[4], lms_inst.c_next[5], lms_inst.c_next[6]);
        $dumpvars(0, lms_inst.correction_term[0], lms_inst.correction_term[1], lms_inst.correction_term[2],
                  lms_inst.correction_term[3], lms_inst.correction_term[4], lms_inst.correction_term[5],
                  lms_inst.correction_term[6]);
        $dumpvars(0, dsp);
    end
`endif

endmodule
