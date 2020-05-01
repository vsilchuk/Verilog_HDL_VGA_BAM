// Module: vga_rgb.v
// Main project: One-channel BAM (Binary angle modulation) signal generator with VGA output.
// Module description: VGA RGB signals generating module.
// Author: github.com/vsilchuk

module vga_rgb (i_clk_27, i_on, i_arst, i_active_area, i_image_active, i_image_drawing, i_new_data, i_mapped_dc, i_prescaler_mode, i_channel_alive, i_hcnt, i_vcnt, i_blank, o_red, o_green, o_blue);

input i_clk_27;
input i_on;
input i_arst;
input i_active_area;
input i_image_active;
input i_image_drawing;
input i_new_data;
input [6:0] i_mapped_dc;	// 0-100%
input [2:0] i_prescaler_mode;
input i_channel_alive;		// is BAM channel alive?
input [9:0] i_hcnt;
input [9:0] i_vcnt;
input i_blank;
output reg [7:0] o_red;
output reg [7:0] o_green;
output reg [7:0] o_blue;

// Text drawing handling - (if i_image_drawing == 0)

parameter [7:0] text_R = 8'd102;			// RGB(102,255,102) - green
parameter [7:0] text_G = 8'd255;			// RGB(255, 0, 255) - Fuchsia color
parameter [7:0] text_B = 8'd102;			// 

parameter [7:0] background_R = {8{1'b0}};	// black background color
parameter [7:0] background_G = {8{1'b0}};	// black background color
parameter [7:0] background_B = {8{1'b0}};	// black background color

parameter [7:0]	char_A = 8'd0, char_B = 8'd1, char_C = 8'd2, char_D = 8'd3, char_E = 8'd4, char_F = 8'd5,
			char_G = 8'd6, char_H = 8'd7, char_I = 8'd8, char_J = 8'd9, char_K = 8'd10, char_L = 8'd11,
			char_M = 8'd12, char_N = 8'd13, char_O = 8'd14, char_P = 8'd15, char_Q = 8'd16, char_R = 8'd17,
			char_S = 8'd18, char_T = 8'd19, char_U = 8'd20, char_V = 8'd21, char_W = 8'd22, char_X = 8'd23,
			char_Y = 8'd24, char_Z = 8'd25, char_0 = 8'd26, char_1 = 8'd27, char_2 = 8'd28, char_3 = 8'd29, 
			char_4 = 8'd30, char_5 = 8'd31, char_6 = 8'd32, char_7 = 8'd33, char_8 = 8'd34, char_9 = 8'd35, 
			char_hash = 8'd36, char_colon = 8'd37, char_percent = 8'd38, char_comma = 8'd39, char_space = 8'd40;
			
// DDRAM (actually, just an memory array)
reg [7:0] ddram [2399:0];	// 80x30 8-bit character cells matrix - 2400 8-bit cells for 8-bit characters

wire [9:0] pixel_column;
wire [9:0] pixel_row;

assign pixel_column = (((i_hcnt - 142) < 0) || ((i_hcnt - 142) > (142 + 635))) ? {10{1'b0}} : (i_hcnt - 142);
assign pixel_row = (((i_vcnt - 34) < 0) || ((i_vcnt - 34) > (34 + 480))) ? {10{1'b0}} : (i_vcnt - 34);

wire [11:0] current_char_cell_number;
assign current_char_cell_number = (79 * (pixel_row / 16) + (pixel_column / 8));

reg [7:0] current_char;		// current char value 

always @(posedge i_clk_27, negedge i_arst) begin 
	if (~i_arst) begin
		current_char <= {8{1'b1}};	// {8{1'b1}};
	end else if (i_image_drawing | i_new_data) begin
		current_char <= {8{1'b1}};
	end else begin
		if (i_on) begin
			if (i_active_area) begin 
				current_char <= ddram[current_char_cell_number];
			end else begin 
				current_char <= {8{1'b1}};
			end
		end else begin
			current_char <= {8{1'b1}};
		end
	end
end

// Character Generator Read-Only Memory module instance
wire [9:0] current_strip_number;			// current 8-bit strip number
assign current_strip_number = (16 * current_char + ((pixel_row) % 16));
						
wire [7:0] current_char_strip;				// current 8-bit strip value
reg [2:0] current_strip_bit;				// 8-bit strip bits 

cgrom cgrom_inst(	.i_clk(i_clk_27),
					.i_char_addr(current_strip_number),
					.o_char_strip(current_char_strip));

// Image drawing handling - (if i_image_drawing == 1)

parameter IMAGE_WIDTH = 8'd128;
parameter IMAGE_HEIGHT = 8'd160;
// parameter IMAGE_PIXELS = IMAGE_WIDTH * IMAGE_HEIGHT;
parameter IMAGE_PIXELS = 15'd20480;
parameter COLOR_DATA_WIDTH = 5'd24;					// R[7:0], G[7:0], B[7:0]
//parameter ADDR_WIDTH = $clog2(IMAGE_PIXELS);		// 15 for 128x160 = 20480 pixels
parameter ADDR_WIDTH = 4'd15;		// 15 for 128x160 = 20480 pixels

reg [ADDR_WIDTH-1:0] cnt;							// current image pixel counter
wire [COLOR_DATA_WIDTH-1:0] rgb_24bit;				// RGB 8-bit color parameters of current image pixel

always @(posedge i_clk_27, negedge i_arst) begin
	if (~i_arst) begin
		cnt <= {ADDR_WIDTH{1'b0}};
	end else if (~i_image_drawing) begin
		cnt <= {ADDR_WIDTH{1'b0}};
	end else if (i_new_data) begin
		cnt <= {ADDR_WIDTH{1'b0}};
	end else if (cnt == IMAGE_PIXELS) begin
		cnt <= {ADDR_WIDTH{1'b0}};
	end else begin
		if (i_on) begin
			if (i_image_active) begin
				cnt <= cnt + 1'b1;
			end else begin
				cnt <= {ADDR_WIDTH{1'b0}};	// cnt <= cnt;
			end
		end else begin
			cnt <= {ADDR_WIDTH{1'b0}};
		end
	end
end

image_rom #(	.IMAGE_WIDTH(IMAGE_WIDTH),
				.IMAGE_HEIGHT(IMAGE_HEIGHT),
				.DATA_WIDTH(COLOR_DATA_WIDTH))

	picture_rom_inst(	.i_clk(i_clk_27),
						.i_pixel_addr(cnt),
						.o_pixel_rgb(rgb_24bit));
						
// Text drawing handling - (if i_image_drawing == 0)
						
always @(posedge i_clk_27, negedge i_arst) begin 
	if (~i_arst) begin
		current_strip_bit <= {3{1'b1}};
	end else if (i_image_drawing) begin
		current_strip_bit <= {3{1'b1}};
	end else if (i_new_data) begin
		current_strip_bit <= {3{1'b1}};
	end else begin
		if (i_on) begin
			if (i_active_area) begin
				current_strip_bit <= current_strip_bit - 1'b1;	// 0 -> 1 -> ... -> 7 -> 0, autooverflow
			end else begin
				current_strip_bit <= {3{1'b1}};
			end
		end else begin
			current_strip_bit <= {3{1'b1}};
		end
	end
end

// RGB color channels output handling

always @(posedge i_clk_27, negedge i_arst) begin
	if (~i_arst) begin
		o_red <= background_R;				// default - background dark color, after the reset and during the ~i_on
		o_green <= background_G;
		o_blue <= background_B;		
	end else if (~i_blank) begin 
		o_red <= background_R;				// default - background dark color
		o_green <= background_G;
		o_blue <= background_B;
	end else begin 
		if (i_on) begin
			if (i_image_drawing) begin
				if (i_image_active) begin
					o_red <= rgb_24bit[23:16];	// image pixel R
					o_green <= rgb_24bit[15:8];	// image pixel G
					o_blue <= rgb_24bit[7:0];	// image pixel B
				end else begin
					o_red <= background_R;		// black background - 1'b1 for "white"
					o_green <= background_G;	// black background
					o_blue <= background_B;		// black background
				end
			end else begin
				if (i_active_area) begin
					if (current_char == 8'd255) begin	// 8'd1
						o_red <= background_R;				// default - background dark color, after the reset and during the ~i_on
						o_green <= background_G;
						o_blue <= background_B;
					end else begin
						if (current_char_strip[current_strip_bit] == 1'b1) begin
						//if (current_char_strip & (1'b1 << current_strip_bit)) begin
							o_red <= text_R;			// current_strip_bit == 1 -> text color
							o_green <= text_G;			//
							o_blue <= text_B;			//
						end else begin 
							o_red <= background_R;		// background dark color
							o_green <= background_G;	//
							o_blue <= background_B;		//
						end 
					end
				end else begin
					o_red <= background_R;				// default - background dark color, after the reset and during the ~i_on
					o_green <= background_G;
					o_blue <= background_B;
				end
				
			end
		end else begin
			o_red <= background_R;				// default - background dark color, after the reset and during the ~i_on
			o_green <= background_G;
			o_blue <= background_B;
		end
	end
end

// Text drawing handling - (if i_image_drawing == 0)

parameter TEXT_LENGTH = 49;

wire [7:0] message [(TEXT_LENGTH-1):0];

assign message[0] = char_hash;
assign message[1] = char_space;
assign message[2] = char_1;
assign message[3] = char_space;
assign message[4] = char_colon;
assign message[5] = char_space;
assign message[6] = i_channel_alive + 5'd26;
assign message[7] = char_space;
assign message[8] = char_comma;
assign message[9] = char_space;
assign message[10] = char_D;
assign message[11] = char_space;
assign message[12] = char_C;
assign message[13] = char_space;
assign message[14] = char_colon;
assign message[15] = char_space;
assign message[16] = (i_mapped_dc / 100) + 5'd26;
assign message[17] = char_space;
assign message[18] = ((i_mapped_dc - ((message[16] - 5'd26) * 100)) / 10) + 5'd26;
assign message[19] = char_space;
assign message[20] = ((i_mapped_dc - ((message[16] - 5'd26) * 100) - ((message[18] - 5'd26) * 10))) + 5'd26;
assign message[21] = char_space;
assign message[22] = char_percent;
assign message[23] = char_space;
assign message[24] = char_comma;
assign message[25] = char_space;
assign message[26] = char_P;
assign message[27] = char_space;
assign message[28] = char_R;
assign message[29] = char_space;
assign message[30] = char_E;
assign message[31] = char_space;
assign message[32] = char_S;
assign message[33] = char_space;
assign message[34] = char_C;
assign message[35] = char_space;
assign message[36] = char_space;
assign message[37] = char_M;
assign message[38] = char_space;
assign message[39] = char_O;
assign message[40] = char_space;
assign message[41] = char_D;
assign message[42] = char_space;
assign message[43] = char_E;
assign message[44] = char_space;
assign message[45] = char_colon;
assign message[46] = char_space;
assign message[47] = i_prescaler_mode + 5'd26;
assign message[48] = char_space;

initial begin 
	integer i;
	for (i = 0; i < TEXT_LENGTH; i = i + 1) begin
		ddram[i] = message[i];		// initial output text configuration
	end
	
	for (i = TEXT_LENGTH; i < 2400; i = i + 1) begin
		ddram[i] = {8{1'b1}};
	end
end 

always @(posedge i_clk_27, negedge i_arst) begin
	if (~i_arst) begin
		//	PER 1 CLOCK CYCLE:	
		integer i;
		
		for (i = 0; i < 2400; i = i + 1) begin
			ddram[i] <= {8{1'b1}};				
		end 
	end else begin
		if (i_on) begin
			if (i_new_data) begin
				//	PER 1 CLOCK CYCLE:	
				
				integer i;
				
				for (i = 0; i < TEXT_LENGTH; i = i + 1) begin
					ddram[i] <= message[i];				// output text configuration
				end 
			end else begin
				integer i;
				
				for (i = 0; i < TEXT_LENGTH; i = i + 1) begin
					ddram[i] <= ddram[i];				// output text configuration
				end 
			end 
		end else begin
			integer i;
			
			for (i = 0; i < 2400; i = i + 1) begin
				ddram[i] <= {8{1'b1}};				
			end 	
		end
	end 
end
endmodule