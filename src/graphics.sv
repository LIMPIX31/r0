module timing_source #
( parameter int unsigned FRAME_WIDTH   = 2200
, parameter int unsigned FRAME_HEIGHT  = 1125
, parameter int unsigned ACTIVE_HEIGHT = 1080
)
( input  var logic i_pclk
, input  var logic i_rst

, output var logic [11:0] o_px
, output var logic [11:0] o_py
, output var logic [8:0]  o_bx
, output var logic [8:0]  o_by

, output var logic o_offscreen
);

    var logic [11:0] x, y;

    always_ff @(posedge i_pclk) begin
        if (i_rst) begin
            {x, y} <= 0;
        end else begin
            x <= x == FRAME_WIDTH - 1 ? 12'd0 : x + 12'd1;
            y <= x == FRAME_WIDTH - 1 ? (y == FRAME_HEIGHT - 1 ? 12'd0 : y + 12'd1) : y;

            o_px <= x;
            o_py <= y;

            o_bx <= x[11:3];
            o_by <= y[11:3];

            o_offscreen <= y >= ACTIVE_HEIGHT;
        end
    end

endmodule : timing_source

module renderer
( input  var logic i_pclk

, input  var logic [15:0] i_char
, input  var logic [11:0] i_x
, input  var logic [11:0] i_y

, output var logic o_hs
, output var logic o_vs
, output var logic o_de

, output var logic [23:0] o_video
);

    // Stage 0

    var logic [7:0]  ascii_0;
    var logic [3:0]  fg_code_0, bg_code_0;
    var logic [11:0] x_0, y_0;

    always_ff @(posedge i_pclk) begin
        ascii_0   <= i_char[15:8];
        fg_code_0 <= i_char[7:4];
        bg_code_0 <= i_char[3:0];

        x_0 <= i_x;
        y_0 <= i_y;
    end

    // Stage 1

    var logic [7:0]  ascii_1;
    var logic [3:0]  fg_code_1, bg_code_1;
    var logic [11:0] x_1, y_1;

    var logic [2:0] cx_1;
    var logic [5:0] cy_1;

    always_ff @(posedge i_pclk) begin
        cx_1 <= (3'd7 - x_0[2:0]);
        cy_1 <= (3'd7 - y_0[2:0]) << 3;

        ascii_1   <= ascii_0;
        fg_code_1 <= fg_code_0;
        bg_code_1 <= bg_code_0;

        x_1 <= x_0;
        y_1 <= y_0;
    end

    // Stage 2

    var logic [3:0]  fg_code_2, bg_code_2;
    var logic [7:0]  ascii_2;
    var logic [63:0] bitmap_2;
    var logic [6:0]  bitpos_2;
    var logic [11:0] x_2, y_2;

    font u_font
    ( .i_clk(i_pclk)
    , .i_ascii(ascii_1)
    , .o_bitmap(bitmap_2)
    );

    always_ff @(posedge i_pclk) begin
        bitpos_2 <= cy_1 + cx_1;

        fg_code_2 <= fg_code_1;
        bg_code_2 <= bg_code_1;

        x_2 <= x_1;
        y_2 <= y_1;
    end

    // Stage 3

    var logic [23:0] fg_true_3, bg_true_3;
    var logic bit_3;

    color_lut u_fg_color
    ( .i_clk(i_pclk)
    , .i_code(fg_code_2)
    , .o_color(fg_true_3)
    );

    color_lut u_bg_color
    ( .i_clk(i_pclk)
    , .i_code(bg_code_2)
    , .o_color(bg_true_3)
    );

    always_ff @(posedge i_pclk) begin
        bit_3 <=  bitmap_2[bitpos_2];
    end

    // Stage 3

    always_ff @(posedge i_pclk) begin
        o_video <= bit_3 == 1 ? fg_true_3 : bg_true_3;
    end

    hvtx_sync #
    ( .FRAME_WIDTH(2200)
    , .FRAME_HEIGHT(1125)
    , .ACTIVE_WIDTH(1920)
    , .ACTIVE_HEIGHT(1080)
    , .H_PORCH(88)
    , .H_SYNC(44)
    , .V_PORCH(4)
    , .V_SYNC(5)
    ) u_sync
    ( .i_clk(i_pclk)
    , .i_x(x_2)
    , .i_y(y_2)
    , .o_hs(o_hs)
    , .o_vs(o_vs)
    , .o_de(o_de)
    );

endmodule : renderer

module font
( input  var logic        i_clk
, input  var logic [7:0]  i_ascii
, output var logic [63:0] o_bitmap
);

    logic [63:0] rom [256];

    always_ff @(posedge i_clk)
        o_bitmap <= rom[i_ascii];

    initial begin
        $readmemh("rom/font.hex", rom);
    end

endmodule : font

module color_lut #
( parameter bit [23:0] X0 = 24'h101010
, parameter bit [23:0] X1 = 24'hEFA6A2
, parameter bit [23:0] X2 = 24'h80C990
, parameter bit [23:0] X3 = 24'hA69460
, parameter bit [23:0] X4 = 24'hA3B8EF
, parameter bit [23:0] X5 = 24'hE6A3DC
, parameter bit [23:0] X6 = 24'h50CACD
, parameter bit [23:0] X7 = 24'h808080
, parameter bit [23:0] X8 = 24'h454545
, parameter bit [23:0] X9 = 24'hE0AF85
, parameter bit [23:0] XA = 24'h5ACCAF
, parameter bit [23:0] XB = 24'hC8C874
, parameter bit [23:0] XC = 24'hCCACED
, parameter bit [23:0] XD = 24'hF2A1C2
, parameter bit [23:0] XE = 24'h74C3E4
, parameter bit [23:0] XF = 24'hC0C0C0
)
( input  var logic        i_clk
, input  var logic [3:0]  i_code
, output var logic [23:0] o_color
);

    logic [23:0] true_colors [16];

    initial begin
        true_colors[0]  = X0;
        true_colors[1]  = X1;
        true_colors[2]  = X2;
        true_colors[3]  = X3;
        true_colors[4]  = X4;
        true_colors[5]  = X5;
        true_colors[6]  = X6;
        true_colors[7]  = X7;
        true_colors[8]  = X8;
        true_colors[9]  = X9;
        true_colors[10] = XA;
        true_colors[11] = XB;
        true_colors[12] = XC;
        true_colors[13] = XD;
        true_colors[14] = XE;
        true_colors[15] = XF;
    end

    always_ff @(posedge i_clk)
        o_color <= true_colors[i_code];

endmodule : color_lut
