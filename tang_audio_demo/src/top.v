module top(
    input clk,
    input resetn,

    output       tmds_clk_n,
    output       tmds_clk_p,
    output [2:0] tmds_d_n,
    output [2:0] tmds_d_p
);

// Tang Nano 4K HDMI audio top module
// To be connected:
// 1. Gowin PLL
// 2. Pixel clock divider
// 3. hdl-util HDMI core
// 4. Gowin LVDS output buffer

endmodule