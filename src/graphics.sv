module timing_source #
( parameter int FRAME_WIDTH   = 1650
, parameter int FRAME_HEIGHT  = 750
, parameter int ACTIVE_HEIGHT = 720
)
( input  logic i_pclk
, input  logic i_rst

, output logic [11:0] o_px
, output logic [11:0] o_py
, output logic [8:0]  o_bx
, output logic [8:0]  o_by

, output logic o_offscreen
);

    logic [11:0] x, y;

    assign o_px = x;
    assign o_py = y;

    assign o_bx = x[11:3];
    assign o_by = y[11:3];

    assign o_offscreen = y >= ACTIVE_HEIGHT;

    always_ff @(posedge i_pclk) begin
        if (i_rst) begin
            x <= 'd0;
            y <= 'd0;
        end else begin
            x <= x == FRAME_WIDTH - 1 ? 12'd0 : x + 12'd1;
            y <= x == FRAME_WIDTH - 1 ? (y == FRAME_HEIGHT - 1 ? 12'd0 : y + 12'd1) : y;
        end
    end

endmodule : timing_source

module renderer
( input logic i_pclk

, input  logic [15:0] i_char
, input  logic [11:0] i_x
, input  logic [11:0] i_y

, output logic o_hs
, output logic o_vs
, output logic o_de

, output logic [23:0] o_video
);

    logic [7:0]  ascii;
    logic [3:0]  fg_code, bg_code;
    logic [23:0] fg_true, bg_true;
    logic [63:0] bitmap;
    logic [2:0]  cx;
    logic [5:0]  cy;
    logic [11:0] x_d, y_d;

    assign ascii   = i_char[15:8];
    assign fg_code = i_char[7:4];
    assign bg_code = i_char[3:0];

    assign cx = (3'd7 - i_x[2:0]);
    assign cy = (3'd7 - i_y[2:0]) << 3;

    always_ff @(posedge i_pclk) begin
        o_video <= bitmap[cy+cx] == 1'b1 ? fg_true : bg_true;

        x_d <= i_x;
        y_d <= i_y;
    end

    font u_font
    ( .i_ascii(ascii)
    , .o_bitmap(bitmap)
    );

    color_lut u_fg_color
    ( .i_code(fg_code)
    , .o_color(fg_true)
    );

    color_lut u_bg_color
    ( .i_code(bg_code)
    , .o_color(bg_true)
    );

    hvtx_sync #
    ( .FRAME_WIDTH(1650)
    , .FRAME_HEIGHT(750)
    , .ACTIVE_WIDTH(1280)
    , .ACTIVE_HEIGHT(720)
    , .H_PORCH(110)
    , .H_SYNC(40)
    , .V_PORCH(5)
    , .V_SYNC(5)
    ) u_sync
    ( .i_clk(i_pclk)
    , .i_x(x_d)
    , .i_y(y_d)
    , .o_hs(o_hs)
    , .o_vs(o_vs)
    , .o_de(o_de)
    );

endmodule : renderer

module font
( input  logic [7:0]  i_ascii
, output logic [63:0] o_bitmap
);

    logic [63:0] rom [256];

    assign o_bitmap = rom[i_ascii];

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
( input  logic [3:0]  i_code
, output logic [23:0] o_color
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

    assign o_color = true_colors[i_code];

endmodule : color_lut
