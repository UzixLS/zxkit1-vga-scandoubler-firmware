`timescale 1ns/100ps

module testbench_scandoubler();

reg rst_n;
reg clk14 = 0;
wire clk14_2;
always #36 clk14 = ~clk14;
assign #18 clk14_2 = clk14;

reg [8:0] vc = 0;
reg [9:0] hc0 = 0;
wire [8:0] hc = hc0[9:1];
wire hc0_reset = hc0 == (448<<1) - 1'b1 ;
wire vc_reset = vc == 320 - 1'b1 ;
always @(posedge clk14) begin
	if (hc0_reset) begin
		hc0 <= 0;
		if (vc_reset)
			vc <= 0;
		else
			vc <= vc + 1'b1;
	end
	else begin
		hc0 <= hc0 + 1'b1;
	end
end

wire hsync0 = hc[8:5] == 4'b1010;
wire vsync0 = vc[7:3] == 5'b11111;
reg csync;
always @(posedge clk14) if (hc[3]) begin
	csync <= ~(vsync0 ^ hsync0);
end

wire [15:0] d;
reg [15:0] ram [0:262143];
reg [15:0] ram_q;
wire [15:0] ram_q0;
assign #10 ram_q0 = ram_q;
wire [17:0] ram_addr_a;
wire n_ramwr;
always @* begin
    if (n_ramwr == 0) begin
        ram[ram_addr_a] <= d;
    end
    ram_q <= ram[ram_addr_a];
end
initial begin
    integer i;
    for (i = 0; i < 262143; i++)
        ram[i] <= 16'h1234;
end
assign d = n_ramwr? ram_q0 : {16{1'bz}};


wire clk28;
scandoubler scandoubler1(
    .R_IN(1'b1),
    .G_IN(1'b1),
    .B_IN(1'b1),
    .I_IN(1'b1),
    .KSI_IN(1'b1),
    .SSI_IN(csync),
    .F14(clk14),
    .F14_2(clk14_2),
    .F28o(clk28),
    .F28(clk28),
    .INVERSE_RGBI(1'b1),
    .INVERSE_KSI(1'b1),
    .INVERSE_SSI(1'b1),
    .INVERSE_F14MHZ(1'b1),
    .VGA_SCART(1'b1),
    .SET_FK_IN(1'b1),
    .SET_FK_OUT(1'b1),
    .R_VGA(),
    .G_VGA(),
    .B_VGA(),
    .I_VGA(),
    .VSYNC_VGA(),
    .HSYNC_VGA(),
    .R_VIDEO(),
    .G_VIDEO(),
    .B_VIDEO(),
    .I_VIDEO(),
    // .SYNC_VIDEO(),
    .A17(ram_addr_a[17]),
    .A(ram_addr_a[16:0]),
    .WE(n_ramwr),
    .OE(),
    .UB(),
    .LB(),
    .D(d)
);

initial begin
    $dumpfile("testbench.vcd");
    $dumpvars();
    rst_n = 0;
    #5 rst_n = 1;
    // #2100000 $finish;
    #21000000 $finish;
end

endmodule
