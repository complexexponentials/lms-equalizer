`timescale 1ns / 1ps 

module mod_m_counter #(
    parameter M = 32
)
(
    input clk,
    input rst,
    input run,
    output max,
    output [$clog2(M-1)-1:0] q
);

wire [$clog2(M-1)-1:0]r_next; 
reg [$clog2(M-1)-1:0]r_reg;

always @(posedge clk) begin
    if (rst)
        r_reg <= 0;
    else if(run)
        r_reg <= r_next;
end

assign r_next = (r_reg == (M-1)) && run ? 0 : r_reg + 1;

assign max = (r_reg == (M-1)) && run ? 1'b1 : 0;

assign q = r_reg;

/*
`ifdef COCOTB_SIM
    initial begin
        $dumpfile("./sim_build/mod_m_counter.vcd");
        $dumpvars(0, mod_m_counter);
    end
`endif
*/

endmodule
