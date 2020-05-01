## One-channel BAM (Binary angle modulation) signal generator with VGA (640x480) output.

###### NTUU KPI, The Faculty of Electronics, The Department of Design of Electronic Digital Equipment (DEDEC/KEOA).

One-channel BAM (Binary angle modulation) signal generator with VGA (640x480) output — tried to make my own VGA module using Verilog HDL.
VGA part provides the ability to display information about the generated BAM-signal on the screen.
You can read a document ["UA_Specification"][3] (in ukrainian), which consists of some description of this project. 

## VGA part consists of: 

+ **VGA signal timings generating module** — `vga_gen.v`;
+ **VGA RGB signals generating module** — `vga_rgb.v`;
+ **Data Display Random Access Memory** — as a part of `vga_rgb.v` module;
+ **Character Generator Read-Only Memory** — `cgrom.v`, which uses the alphabet I created — see `Alphabet.xlsx` and `cgrom_source.bin`;
+ **128x160 pixels image Read-Only Memory** — `picture_rom.v` — stores a test image — see `image_source_green.bin` and `image_source_white.bin`;

I used the **Quartus II** to synthesize this project, and a **Altera DE2 Development and Education Board** to test its performance.

## The assignment of the buttons, switches and LEDs on the board:

+ **SW[0]** — on/off;
+ **SW[1]** — BAM channel on/off;
+ **SW[2]** — image mode;
+ **SW[3:5]** — prescaler value;
+ **SW[13:6]** — duty cycle value;


+ **LEDR[0]** — on/off;
+ **LEDR[1]** — BAM channel output;
+ **LEDR[2]** — show buttons latching - vga_redraw;
+ **LEDG[1]** — BAM channel alive/enable;


+ **KEY[0]** — ARST;
+ **KEY[1]** — prescaler mode value latch;
+ **KEY[2]** — duty cycle value latch;

Altera DE2 pin assignments file — from [here][4].

---

+ Altera DE2 board VGA timings — from [DE2 User Manual][5]:
![Altera DE2 VGA timings](https://github.com/vsilchuk/Verilog_HDL_VGA_BAM/blob/master/img/altera_de2_vga_timings.png "Altera DE2 VGA timings")

![VGA timings](https://github.com/vsilchuk/Verilog_HDL_VGA_BAM/blob/master/img/altera_de2_vga_timings_2.png "VGA timings")

+ DE2 board view:
![DE2 board view](https://github.com/vsilchuk/Verilog_HDL_VGA_BAM/blob/master/img/altera_de2.png "DE2 board view")

+ BAM configuration information — Channel #1, on ("1"), duty cycle = 100%, prescaler mode = 5 (1:32):
![BAM configuration information](https://github.com/vsilchuk/Verilog_HDL_VGA_BAM/blob/master/img/bam_config_info_pm_5.png "BAM configuration information")

+ BAM configuration information — Channel #1, on ("1"), duty cycle = 100%, prescaler mode = 7 (1:128):
![BAM configuration information](https://github.com/vsilchuk/Verilog_HDL_VGA_BAM/blob/master/img/bam_config_info_pm_7.png "BAM configuration information")

+ Test image displaying — Channel #1, on ("1"), duty cycle = 100%, prescaler mode = 7 (1:128):
![Green test image](https://github.com/vsilchuk/Verilog_HDL_VGA_BAM/blob/master/img/test_image_displaying.png "Green test image")

## Links:

+ Altera DE2 Development and Education Board — related materials — [Link][6].

[3]: https://github.com/vsilchuk/Verilog_HDL_VGA_BAM/blob/master/doc/UA_Specification.pdf
[4]: https://github.com/KorotkiyEugene/intel_fpga_boards/blob/master/DE2/DE2_pin_assignments.csv
[5]: https://github.com/KorotkiyEugene/intel_fpga_boards/blob/master/DE2/Manual/DE2_UserManual_1.6.pdf
[6]: https://github.com/KorotkiyEugene/intel_fpga_boards/tree/master/DE2
