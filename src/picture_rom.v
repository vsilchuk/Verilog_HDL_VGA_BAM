// Module: picture_rom.v
// Main project: One-channel BAM (Binary angle modulation) signal generator with VGA output.
// Module description: 128x160 (IMAGE_WIDTH x IMAGE_HEIGHT) pixels image ROM.
// Author: github.com/vsilchuk

`define IMAGE_SOURCE "image_source_green.bin"

module image_rom(i_clk, i_pixel_addr, o_pixel_rgb);

parameter IMAGE_WIDTH = 128;
parameter IMAGE_HEIGHT = 160;
parameter CELLS_NUM = IMAGE_WIDTH * IMAGE_HEIGHT;	// 20480 * 24-bit cells 

parameter DATA_WIDTH = 24;							// R[7:0], G[7:0], B[7:0]
parameter ADDR_WIDTH = $clog2(CELLS_NUM);			// 15 for 128x160 = 20480 cells

parameter [DATA_WIDTH-1:0] ROM_DEFLT_DATA = {DATA_WIDTH{1'b0}};	// RGB(0,0,0) - {R(8'b00000000), G(8'b00000000), B(8'b00000000)}

input i_clk;
input [ADDR_WIDTH-1:0] i_pixel_addr;
output reg [DATA_WIDTH-1:0] o_pixel_rgb;			// 24-bit pixel's RGB values

// reg [DATA_WIDTH-1:0] image_rom[(CELLS_NUM-1):0];		// 20480 * 24-bit cells
reg [23:0] image_rom[20479:0];

initial begin
	integer i;
	for (i = 0; i < CELLS_NUM; i = i + 1) begin
		image_rom[i] = ROM_DEFLT_DATA;				// RGB(0,0,0), filling with default data at first
	end 
	
	$readmemb(`IMAGE_SOURCE, image_rom);			//  read the memory contents from the file PICTURE_SOURCE
end

always @(posedge i_clk) begin
	if(i_pixel_addr > CELLS_NUM-1) begin
		o_pixel_rgb <= ROM_DEFLT_DATA;
	end else begin
		o_pixel_rgb <= image_rom[i_pixel_addr];
	end 
end 
endmodule