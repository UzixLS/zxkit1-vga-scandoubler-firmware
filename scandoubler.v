module scandoubler(
    input R_IN,
    input G_IN,
    input B_IN,
    input I_IN,

    input KSI_IN,
    input SSI_IN,
    input F14,
    input F14_2,
    output F28o,
    input F28,

    input INVERSE_RGBI,
    input INVERSE_KSI,
    input INVERSE_SSI,
    input INVERSE_F14MHZ,
    input VGA_SCART,
    input SET_FK_IN,
    input SET_FK_OUT,

    output reg R_VGA,
    output reg G_VGA,
    output reg B_VGA,
    output reg [2:0] I_VGA,
    output reg VSYNC_VGA,
    output reg HSYNC_VGA,

    output R_VIDEO,
    output G_VIDEO,
    output B_VIDEO,
    output [2:0] I_VIDEO,
    // output SYNC_VIDEO,

    output A17,
    output reg [16:0] A,
    output reg WE,
    output reg UB,
    output reg LB,
    output OE,
    inout [15:0] D
);

assign F28o = F14 ^ F14_2 ^ INVERSE_F14MHZ;

reg ssi = 0, ksi0 = 0;
wire ksi = ksi0 ^ ~KSI_IN;
reg [7:0] ssi_cnt = 0;
reg [7:0] ssi_len = 0;
always @(posedge F28) begin
    if (SSI_IN == ksi0) begin
        ssi_cnt <= ssi_cnt + 1'b1;
        if (&ssi_cnt)
            ksi0 <= ~ksi0;
        ssi <= 1'b0;
    end
    else if (|ssi_cnt) begin
        ssi_len <= ssi_cnt;
        ssi_cnt <= 0;
        ssi <= 1'b1;
    end
    else begin
        ssi <= 1'b0;
    end
end

reg [11:0] hcnt_in = 0;
reg [11:0] hlen = 0;
reg even_line = 0;
always @(posedge F28) begin
    if (ssi) begin
        even_line <= !even_line;
        hlen <= hcnt_in;
        hcnt_in <= 0;
    end
    else begin
        hcnt_in <= hcnt_in + 1'b1;
    end
end

reg [10:0] hcnt_vga = 0;
always @(posedge F28) begin
    if (hcnt_vga == hlen[11:1] || ssi)
        hcnt_vga <= 0;
    else
        hcnt_vga <= hcnt_vga + 1'b1;
end

assign A17 = 1'b0;
assign OE = 1'b0;
wire write_pixel = ~hcnt_in[0];
reg [3:0] ibgr_reg1, ibgr_reg2, ibgr_in;
always @(posedge F28) begin
    WE <= ~write_pixel;
    LB <= write_pixel?  hcnt_in[1] : 1'b0;
    UB <= write_pixel? ~hcnt_in[1] : 1'b0;
    A[16:0] <= write_pixel?
        {{6{1'b0}}, ~even_line, hcnt_in[11:2]} :
        {{6{1'b0}},  even_line, hcnt_vga[10:1]} ;

    ibgr_in = {4{~INVERSE_RGBI}} ^ {I_IN, B_IN, G_IN, R_IN};
    if (write_pixel) begin
        ibgr_reg1 <= D[3:0];
        ibgr_reg2 <= D[11:8];
    end
    else begin
        ibgr_reg1 <= ibgr_reg2;
    end
end

assign D[15:0] = !write_pixel?
    {{4{1'b0}}, ibgr_in, {4{1'b0}}, ibgr_in} :
    {16{1'bz}} ;

wire HBLANK_VGA = (hcnt_vga < (ssi_len[7:1]+ssi_len[7:2]));
always @(posedge F28) begin
    VSYNC_VGA <= ~INVERSE_KSI ^ ksi;
    HSYNC_VGA <= ~INVERSE_SSI ^ (hcnt_vga < ssi_len[7:1]);
    R_VGA     <= !HBLANK_VGA && (ibgr_reg1[0]               );
    G_VGA     <= !HBLANK_VGA && (ibgr_reg1[1]               );
    // G_VGA     <= !HBLANK_VGA && hcnt_vga[1];
    B_VGA     <= !HBLANK_VGA && (ibgr_reg1[2]               );
    I_VGA[0]  <= !HBLANK_VGA && (ibgr_reg1[0] & ibgr_reg1[3]);
    I_VGA[1]  <= !HBLANK_VGA && (ibgr_reg1[1] & ibgr_reg1[3]);
    I_VGA[2]  <= !HBLANK_VGA && (ibgr_reg1[2] & ibgr_reg1[3]);
end

assign R_VIDEO    = R_IN ^ ~INVERSE_RGBI;
assign G_VIDEO    = G_IN ^ ~INVERSE_RGBI;
assign B_VIDEO    = B_IN ^ ~INVERSE_RGBI;
assign I_VIDEO[0] = I_IN ^ ~INVERSE_RGBI;
assign I_VIDEO[1] = I_IN ^ ~INVERSE_RGBI;
assign I_VIDEO[2] = I_IN ^ ~INVERSE_RGBI;
// assign SYNC_VIDEO = ~((SSI_IN ^ ~INVERSE_SSI) ^ (KSI_IN ^ ~INVERSE_KSI));


endmodule
