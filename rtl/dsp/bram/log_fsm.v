`timescale 1ns / 1ps 

module log_fsm(
    input clk,
    input rst,
    input run,
    input last_addr,
    output write
);

reg current_state;
reg next_state;

localparam WAIT_INIT = 1'b0;
localparam WRITING = 1'b1;

// Next state logic
always @(*) begin
    next_state = current_state;

    case(current_state)
        WAIT_INIT: begin
            if (run)
                next_state = WRITING;
        end
        WRITING: begin
            if (last_addr)
                next_state = WAIT_INIT;
        end
        default:
            next_state = current_state;
    endcase
end

// Output logic

assign write = current_state;

always @(posedge clk) begin
    if (rst)
        current_state <= WAIT_INIT;
    else
        current_state <= next_state;
end

endmodule
