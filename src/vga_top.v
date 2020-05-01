// Module: vga_top.v
// Main project: One-channel BAM (Binary angle modulation) signal generator with VGA output.
// Module description: Top module for the VGA&BAM project.
// Author: github.com/vsilchuk

module vga_top (CLOCK_50, SW, KEY, LEDR, LEDG, VGA_CLK, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_SYNC, VGA_BLANK);

input CLOCK_50;
input [13:0] SW;
input [2:0] KEY;
output wire [2:0] LEDR;
output wire [1:0] LEDG;
output wire VGA_CLK;
output wire [7:0] VGA_R;
output wire [7:0] VGA_G;
output wire [7:0] VGA_B;
output wire VGA_HS;
output wire VGA_VS;
output wire VGA_SYNC;
output wire VGA_BLANK;

// SW[0] -> ON/OFF 
// SW[1] -> BAM CHANNEL ON/OFF
// SW[2] -> IMAGE MODE
// SW[3:5] -> PRESCALER
// SW[13:6] -> DUTY CYCLE

// LEDR[1] -> BAM CHANNEL OUTPUT
// LEDG[1] -> BAM CHANNEL ALIVE/ENABLE
// LEDR[0] -> ON/OFF
// LEDR[2] -> SHOW BUTTONS LATCHING - VGA_REDRAW

// KEY[0] -> ARST
// KEY[1] -> presc_latch
// KEY[2] -> dc_latch

// 25 MHz clock generator start 
reg clock_25;

always @(posedge CLOCK_50) begin
	clock_25 <= ~clock_25;
end

assign VGA_CLK = clock_25;
// 25 MHz clock generator end 

reg [7:0] bam_duty_cycle;
reg [2:0] bam_precsaler_mode;

wire vga_active_area, vga_image_active;
wire [9:0] pixel_column;
wire [9:0] pixel_row;

wire device_on_off;
assign device_on_off = SW[0];
wire bam_on_off;
assign bam_on_off = SW[1];
wire image_drawing;
assign image_drawing = SW[2];
wire [2:0] prescaler_mode;
assign prescaler_mode = SW[5:3];
wire [7:0] duty_cycle;
assign duty_cycle = SW[13:6];
wire arst;
assign arst = KEY[0];
wire dc_latch;
assign dc_latch = ~KEY[2];
wire presc_latch;
assign presc_latch = ~KEY[1];

wire bam_chanel_output;
assign LEDR[1] = bam_chanel_output;
wire bam_alive;
assign LEDG[1] = bam_alive;
wire bam_enable;
assign bam_enable = (device_on_off & bam_on_off);

wire vga_redraw;
assign vga_redraw = (presc_latch | dc_latch);

reg vga_redraw_led;
assign LEDR[2] = vga_redraw_led;

assign LEDR[0] = device_on_off;

always @(posedge CLOCK_50, negedge arst) begin
	if (~arst) begin
		vga_redraw_led <= 1'b0;
	end else begin 
		if (device_on_off) begin
			if (vga_redraw) begin 
				vga_redraw_led <= ~vga_redraw_led;
			end else begin
				vga_redraw_led <= vga_redraw_led;
			end
		end else begin
			vga_redraw_led <= 1'b0;
		end
	end
end

always @(posedge CLOCK_50, negedge arst) begin
	if (~arst) begin
		bam_duty_cycle <= {8{1'b0}};
	end else begin
		if (device_on_off) begin
			// if (dc_latch) begin
			if (~KEY[2]) begin
				bam_duty_cycle <= SW[13:6];
			end else begin	
				bam_duty_cycle <= bam_duty_cycle;
			end
		end else begin
			bam_duty_cycle <= {8{1'b0}};
		end
	end
end

always @(posedge CLOCK_50, negedge arst) begin
	if (~arst) begin
		bam_precsaler_mode <= {3{1'b0}};
	end else begin
		if (device_on_off) begin
			//if (presc_latch) begin
			if (~KEY[1]) begin
				bam_precsaler_mode <= SW[5:3];
			end else begin	
				bam_precsaler_mode <= bam_precsaler_mode;
			end
		end else begin
			bam_precsaler_mode <= {3{1'b0}};
		end
	end
end

wire [6:0] dc_map_to_percent;	// 0-100%, 2^7 = 128
assign dc_map_to_percent = (bam_duty_cycle - 0) * (100 - 0) / (255 - 0) + 0;

BAM bam_inst (	.i_clk(CLOCK_50),
				.i_arst(~arst),
				.i_on(bam_enable),
				.i_presc_mode(bam_precsaler_mode),
				.i_duty_cycle(bam_duty_cycle),
				.o_bam_enable(bam_alive),
				.o_signal(bam_chanel_output));

wire image_active;

wire [9:0] hcnt;
wire [9:0] vcnt;
				
vga_gen vga_gen_inst (	.i_clk_27(VGA_CLK),
						.i_on(device_on_off),
						.i_arst(arst),
						.o_active_area(vga_active_area),
						.o_image_active(image_active),
						.o_hcnt(hcnt),
						.o_vcnt(vcnt),
						.o_hsync(VGA_HS),
						.o_vsync(VGA_VS),
						.o_blank(VGA_BLANK),
						.o_sync(VGA_SYNC));				
												
vga_rgb vga_rgb_inst (	.i_clk_27(VGA_CLK),
						.i_on(device_on_off),
						.i_arst(arst),
						.i_active_area(vga_active_area),
						.i_image_active(image_active),
						.i_image_drawing(image_drawing),
						.i_new_data(vga_redraw),
						.i_mapped_dc(dc_map_to_percent),
						.i_prescaler_mode(bam_precsaler_mode),
						.i_channel_alive(bam_alive),
						.i_hcnt(hcnt),
						.i_vcnt(vcnt),
						.i_blank(VGA_BLANK),
						.o_red(VGA_R),
						.o_green(VGA_G),
						.o_blue(VGA_B));
endmodule