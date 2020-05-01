// Module: vga_gen.v
// Main project: One-channel BAM (Binary angle modulation) signal generator with VGA output.
// Module description: VGA signal timings generating module.
// Author: github.com/vsilchuk

module vga_gen (i_clk_27, i_on, i_arst, o_active_area, o_image_active, o_hcnt, o_vcnt, o_hsync, o_vsync, o_blank, o_sync);

input i_clk_27;
input i_on;
input i_arst;
output wire o_active_area;
output wire o_image_active;
output reg [9:0] o_hcnt;
output reg [9:0] o_vcnt;	
output wire o_hsync; 
output wire o_vsync;
output wire o_blank;
output wire o_sync;

// H-timings
parameter h_sync = 95;			// 3,8 us
parameter h_back_porch = 48;	// (47,5) 1,9 us
parameter h_active = 635;		// 25,4 us
parameter h_front_porch = 15;	// 0,6 us

parameter h_before_blank_end = h_sync + h_back_porch;
parameter h_after_blank_start = h_sync + h_back_porch + h_active;
parameter h_total = h_sync + h_back_porch + h_active + h_front_porch;

// V-timings
parameter v_sync = 2;			// lines 
parameter v_back_porch = 33;	// lines
parameter v_active = 480;		// lines
parameter v_front_porch = 10;	// lines

parameter v_before_blank_end = v_sync + v_back_porch;
parameter v_after_blank_start = v_sync + v_back_porch + v_active;
parameter v_total = v_sync + v_back_porch + v_active + v_front_porch;

wire h_blank, v_blank;
assign h_blank = ~((o_hcnt < h_before_blank_end) | (o_hcnt >= h_after_blank_start));
assign v_blank = ~((o_vcnt < v_before_blank_end) | (o_vcnt >= v_after_blank_start));

// Control signals assignments
assign o_hsync = (o_hcnt < h_sync) ? 1'b0 : 1'b1;	// active LOW
assign o_vsync = (o_vcnt < v_sync) ? 1'b0 : 1'b1;	// active LOW
assign o_blank = (h_blank | v_blank);
assign o_sync = 1'b0;							// to GND, no sync-on-green is allowed

assign o_active_area = ((o_hcnt >= h_before_blank_end) && (o_hcnt < h_after_blank_start) && (o_vcnt >= v_before_blank_end) && (o_vcnt < v_after_blank_start));		

// Image borders
parameter h_image_start = h_sync + h_back_porch;
parameter h_image_end = h_sync + h_back_porch + 8'd128;

parameter v_image_start = v_sync + v_back_porch;
parameter v_image_end = v_sync + v_back_porch + 8'd160;

assign o_image_active = ((o_hcnt >= h_image_start) && (o_hcnt < h_image_end) && (o_vcnt >= v_image_start) && (o_vcnt < v_image_end));		

always @(posedge i_clk_27, negedge i_arst) begin 	
	if (~i_arst) begin
		o_hcnt <= {10{1'b0}};
		o_vcnt <= {10{1'b0}};
	end else begin 
		if (i_on) begin
			if (o_hcnt < h_total - 1) begin
				o_hcnt <= o_hcnt + 1'b1;
			end else begin 
				o_hcnt <= {10{1'b0}};
			
				if (o_vcnt < v_total - 1) begin 
					o_vcnt <= o_vcnt  + 1'b1;
				end else begin
					o_vcnt <= {10{1'b0}};
				end
			end
		end else begin
			o_hcnt <= {10{1'b0}};
			o_vcnt <= {10{1'b0}};
		end
	end
end
endmodule