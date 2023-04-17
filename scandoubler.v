module scandoubler(
    input R_IN,
    input G_IN,
    input B_IN,
    input I_IN,

    input KSI_IN,
    input SSI_IN,
    input F14,
    input F14_2,

    input INVERSE_RGBI,
    input INVERSE_KSI,
    input INVERSE_SSI,
    input INVERSE_F14MHZ,
    input VGA_SCART,
    input SET_FK_IN,
    input SET_FK_OUT,

    output R_VGA,
    output G_VGA,
    output B_VGA,
    output [2:0] I_VGA,
    output VSYNC_VGA,
    output HSYNC_VGA,

    output R_VIDEO,
    output G_VIDEO,
    output B_VIDEO,
    output [2:0] I_VIDEO,
    output SYNC_VIDEO,

    output A17,
    output [16:0] A,
    output WE,
    output OE,
    output UB,
    output LB,
    inout [15:0] D
);


reg ssi = 0, ksi0 = 0;
wire ksi = ksi0 ^ ~KSI_IN;
reg [6:0] ssi_cnt = 0;
always @(posedge F14) begin
    if (SSI_IN == ksi0) begin
        ssi_cnt <= ssi_cnt + 1'b1;
        if (&ssi_cnt)
            ksi0 <= ~ksi0;
        ssi <= 1'b0;
    end
    else if (|ssi_cnt) begin
        ssi_cnt <= 0;
        ssi <= 1'b1;
    end
    else begin
        ssi <= 1'b0;
    end
end

reg [10:0] hcnt = 0;
reg [10:0] hlen = 0;
reg even_line = 0;
always @(posedge F14) begin
    if (ssi) begin
        even_line = !even_line;
        hlen <= hcnt;
        hcnt <= 0;
    end
    else begin
        hcnt <= hcnt + 1'b1;
    end
end

reg [9:0] hcnt_vga = 0;
always @(posedge F14) begin
    if (hcnt_vga == hlen[10:1] || ssi)
        hcnt_vga <= 0;
    else
        hcnt_vga <= hcnt_vga + 1'b1;
end

assign VSYNC_VGA = ~INVERSE_KSI ^ ksi;
assign HSYNC_VGA = ~INVERSE_SSI ^ (hcnt_vga < 54); // ~3.85us

assign OE = 1'b0;
assign A17 = 1'b0;
wire write_screen = F14 ^ INVERSE_F14MHZ & !ssi;
assign WE = ~write_screen;
assign UB = write_screen? ~hcnt[0] : 1'b0;
assign LB = write_screen?  hcnt[0] : 1'b0;
assign A[16:0] = write_screen?
    {{6{1'b0}}, ~even_line, hcnt[10:1]} :
    {{6{1'b0}},  even_line, hcnt_vga} ;

assign D[15:0] = write_screen? {{4{1'b0}}, I_IN, B_IN, G_IN, R_IN, {4{1'b0}}, I_IN, B_IN, G_IN, R_IN} : {16{1'bz}};

reg [3:0] ibgr_reg1, ibgr_reg2;
always @(posedge F14) begin
    if (write_screen) begin
        ibgr_reg1 <= D[3:0];
        ibgr_reg2 <= D[11:8];
    end
end

assign R_VGA    = (~INVERSE_RGBI) ^ (F14? ibgr_reg2[0] : ibgr_reg1[0]);
assign G_VGA    = (~INVERSE_RGBI) ^ (F14? ibgr_reg2[1] : ibgr_reg1[1]);
assign B_VGA    = (~INVERSE_RGBI) ^ (F14? ibgr_reg2[2] : ibgr_reg1[2]);
assign I_VGA[0] = (~INVERSE_RGBI) ^ (F14? ibgr_reg2[3] : ibgr_reg1[3]);
assign I_VGA[1] = (~INVERSE_RGBI) ^ (F14? ibgr_reg2[3] : ibgr_reg1[3]);
assign I_VGA[2] = (~INVERSE_RGBI) ^ (F14? ibgr_reg2[3] : ibgr_reg1[3]);

assign R_VIDEO    = R_IN ^ ~INVERSE_RGBI;
assign G_VIDEO    = G_IN ^ ~INVERSE_RGBI;
assign B_VIDEO    = B_IN ^ ~INVERSE_RGBI;
assign I_VIDEO[0] = I_IN ^ ~INVERSE_RGBI;
assign I_VIDEO[1] = I_IN ^ ~INVERSE_RGBI;
assign I_VIDEO[2] = I_IN ^ ~INVERSE_RGBI;
assign SYNC_VIDEO = ~((SSI_IN ^ ~INVERSE_SSI) ^ (KSI_IN ^ ~INVERSE_KSI));


endmodule
