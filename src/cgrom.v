// Module: cgrom.v
// Main project: One-channel BAM (Binary angle modulation) signal generator with VGA output.
// Module description: Character Generator ROM.
// Author: github.com/vsilchuk

`define CGROM_SOURCE "cgrom_source.bin"

module cgrom(i_clk, i_char_addr, o_char_strip);

parameter DATA_WIDTH = 8, ADDR_WIDTH = 10, CHAR_STRIPS = 656;	// 41*16 = 656 * 8-bit strips
parameter [DATA_WIDTH-1:0] ROM_DEFLT_DATA = {DATA_WIDTH{1'b0}};
parameter [ADDR_WIDTH-1:0] ROM_END_ADDR = CHAR_STRIPS;

input i_clk;
input [ADDR_WIDTH-1:0] i_char_addr;
output reg [DATA_WIDTH-1:0] o_char_strip;	// 8-bit strip part of 16x8 bits character

reg [DATA_WIDTH-1:0] cgrom [CHAR_STRIPS-1:0];	// 41 * 16 * 8

initial begin
	integer i;
	for (i = 0; i < CHAR_STRIPS; i = i + 1) begin
		cgrom[i] = ROM_DEFLT_DATA;
	end 
	
	$readmemb(`CGROM_SOURCE, cgrom);		//  read the memory contents in the file CGROM_SOURCE
end

always @(posedge i_clk) begin
	if(i_char_addr > ROM_END_ADDR) begin
		o_char_strip <= ROM_DEFLT_DATA;
	end else begin
		o_char_strip <= cgrom[i_char_addr];
	end 
end 
endmodule