`timescale 1ns / 1ps 

module bram
(
    input           clockdsp,
    input           soft_reset,
    input           log_in_ram_run_from_micro,
    input [14:0]    log_read_addr_from_micro,
    input [2:0]     log_input_select,
    output          log_out_full_from_ram,
    output [31:0]   log_data_from_ram,
    // Log inputs
    input [10:0]    log_in_1,
    input [8:0]     log_in_2,
    input [7:0]     log_in_3,
    input           log_in_4
);

wire last_addr;
wire write_mem;
wire [14:0]address_mem;
wire [14:0]test_data;
reg  [31:0]data_mem;

reg [10:0]    log_in_1_reg;
reg [8:0]     log_in_2_reg;
reg [7:0]     log_in_3_reg;
reg           log_in_4_reg;

mod_m_counter #(
    .M(32768)
)
address_count(
    .clk(clockdsp),
    .rst(soft_reset),
    .run(write_mem),
    .max(last_addr),
    .q(address_mem)
);

assign log_out_full_from_ram = last_addr;

always @(posedge clockdsp) begin
    if (soft_reset) begin
        log_in_1_reg <= 0;
        log_in_2_reg <= 0;
        log_in_3_reg <= 0;
        log_in_4_reg <= 0;
    end
    else begin
        log_in_1_reg <= log_in_1;
        log_in_2_reg <= log_in_2;
        log_in_3_reg <= log_in_3;
        log_in_4_reg <= log_in_4;
    end
end

always @(*) begin
    case(log_input_select)
        3'd0: data_mem = { {21{log_in_1_reg[10]}}, log_in_1_reg};
        3'd1: data_mem = { {23{log_in_2_reg[8]}}, log_in_2_reg};
        3'd2: data_mem = { {24{log_in_3_reg[7]}}, log_in_3_reg};
        3'd3: data_mem = {32{1'b0}};
        default : data_mem = { {21{1'b0}}, log_in_1_reg};
    endcase
end

dual_port_ram #(
    .WIDTH(32),
    .DEPTH(32768)
    )
log_ram(  
    .clk(clockdsp),
    .we(write_mem),
    .address_a(address_mem),
    .address_b(log_read_addr_from_micro),
    .din(data_mem),
    .dout_a(),
    .dout_b(log_data_from_ram)
);

log_fsm fsm(  
    .clk(clockdsp),
    .rst(soft_reset),
    .run(log_in_ram_run_from_micro),
    .last_addr(last_addr),
    .write(write_mem)
);

//`ifdef COCOTB_SIM
//     initial begin
//         $dumpfile("./sim_build/bram.vcd");
//         $dumpvars(0, bram);
//     end
//`endif


endmodule
