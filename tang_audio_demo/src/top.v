module top(
    input clk,
    input resetn,

    output       tmds_clk_n,
    output       tmds_clk_p,
    output [2:0] tmds_d_n,
    output [2:0] tmds_d_p
);

wire clk_p5;
wire clk_p;
wire pll_lock;
wire sys_resetn;

wire [2:0] tmds;
wire tmds_clock;

wire reset;
assign reset = ~sys_resetn;

// Temporary audio clock for compile test.
// Later we will replace this with proper audio sample timing.
wire clk_audio;
assign clk_audio = clk_p;

Gowin_CLKDIV u_div_5 (
    .clkout(clk_p),
    .hclkin(clk_p5),
    .resetn(pll_lock)
);

Gowin_PLLVR Gowin_PLLVR_inst(
    .clkout(clk_p5),
    .lock(pll_lock),
    .clkin(clk)
);

Reset_Sync u_Reset_Sync (
    .resetn(sys_resetn),
    .ext_reset(resetn & pll_lock),
    .clk(clk_p)
);

// Simple internal audio generator
reg [15:0] audio_left  = 16'd0;
reg [15:0] audio_right = 16'd0;

always @(posedge clk_audio) begin
    if (reset) begin
        audio_left  <= 16'd0;
        audio_right <= 16'd0;
    end else begin
        audio_left  <= audio_left + 16'd256;
        audio_right <= audio_right - 16'd256;
    end
end

// Simple RGB test pattern
wire [9:0] cx;
wire [9:0] cy;
wire [9:0] frame_width;
wire [9:0] frame_height;
wire [9:0] screen_width;
wire [9:0] screen_height;

reg [23:0] rgb = 24'd0;

always @(posedge clk_p) begin
    if (reset) begin
        rgb <= 24'h000000;
    end else begin
        rgb <= {
            (cx[7:0]),
            (cy[7:0]),
            8'h80
        };
    end
end

hdmi #(
    .VIDEO_ID_CODE(1),
    .VIDEO_REFRESH_RATE(59.94),
    .AUDIO_RATE(48000),
    .AUDIO_BIT_WIDTH(16)
) hdmi_inst (
    .clk_pixel_x5(clk_p5),
    .clk_pixel(clk_p),
    .clk_audio(clk_audio),
    .reset(reset),
    .rgb(rgb),
    .audio_sample_word('{audio_left, audio_right}),
    .tmds(tmds),
    .tmds_clock(tmds_clock),
    .cx(cx),
    .cy(cy),
    .frame_width(frame_width),
    .frame_height(frame_height),
    .screen_width(screen_width),
    .screen_height(screen_height)
);

ELVDS_OBUF tmds_bufds [3:0] (
    .I({tmds_clock, tmds}),
    .O({tmds_clk_p, tmds_d_p}),
    .OB({tmds_clk_n, tmds_d_n})
);

endmodule


module Reset_Sync (
    input clk,
    input ext_reset,
    output resetn
);

reg [3:0] reset_cnt = 0;

always @(posedge clk or negedge ext_reset) begin
    if (~ext_reset)
        reset_cnt <= 4'b0;
    else
        reset_cnt <= reset_cnt + !resetn;
end

assign resetn = &reset_cnt;

endmodule