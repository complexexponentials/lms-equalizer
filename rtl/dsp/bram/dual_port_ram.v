// Dual-PortRAM with SynchronousRead (ReadThrough)

module dual_port_ram #(
    parameter WIDTH = 32,
    parameter DEPTH = 32768)
(
    input clk,
    input we,
    input [$clog2(DEPTH-1) - 1:0] address_a,
    input [$clog2(DEPTH-1) - 1:0] address_b,
    input [WIDTH - 1:0] din,
    output [WIDTH - 1:0] dout_a,
    output [WIDTH - 1:0] dout_b
);

reg [WIDTH-1:0] ram [DEPTH-1:0];
reg [WIDTH-1:0] read_addr_a;
reg [WIDTH-1:0] read_addr_b;

always @(posedge clk) begin
    if (we) 
        ram[address_a] <= din;
        
    read_addr_a <= address_a;
    read_addr_b <= address_b;
    
end

assign dout_a = ram[read_addr_a];
assign dout_b = ram[read_addr_b];

endmodule
