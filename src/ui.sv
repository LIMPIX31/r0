package ui;

    localparam bit [9:0] ADDR_ZERO         = 10'h00;
    localparam bit [9:0] ADDR_BACKGROUND   = ADDR_ZERO         + 10'h00; // 1
    localparam bit [9:0] ADDR_LABEL_LAST   = ADDR_BACKGROUND   + 10'h01; // 6
    localparam bit [9:0] ADDR_LAST_RESULT  = ADDR_LABEL_LAST   + 10'h06; // 13
    localparam bit [9:0] ADDR_LABEL_BEST   = ADDR_LAST_RESULT  + 10'h0D; // 6
    localparam bit [9:0] ADDR_BEST_RESULT  = ADDR_LABEL_BEST   + 10'h06; // 13
    localparam bit [9:0] ADDR_STATUS_LABEL = ADDR_BEST_RESULT  + 10'h0D; // 18
    localparam bit [9:0] ADDR_LABEL_PRNG   = ADDR_STATUS_LABEL + 10'h12; // 6
    localparam bit [9:0] ADDR_DBG_RND      = ADDR_LABEL_PRNG   + 10'h06; // 1
    localparam bit [9:0] ADDR_UNITS        = ADDR_DBG_RND      + 10'h01; // 19
    localparam bit [9:0] ADDR_AUTHOR       = ADDR_UNITS        + 10'h13; // 17

endpackage : ui

module state_ram
    import ui::*;
( input logic i_wclk
, input logic i_rclk
, input logic i_we

, input logic [9:0] i_waddr
, input logic [9:0] i_raddr

, input  logic [15:0] i_din
, output logic [15:0] o_dout
);

    logic [15:0] ram [1024];

    always_ff @(posedge i_wclk) begin
        if (i_we) begin
            ram[i_waddr] <= i_din;
        end
    end

    always_ff @(posedge i_rclk) begin
        if (!i_we) begin
            o_dout <= ram[i_raddr];
        end
    end

endmodule : state_ram

module state_transfer
    import ui::*;
( input logic i_clk
, input logic i_offscreen

, input logic [2:0]  i_reaction_state
, input logic [27:0] i_last_result
, input logic [27:0] i_best_result
, input logic [15:0] i_dbg_rnd

, output logic        o_sr_we
, output logic [9:0]  o_sr_waddr
, output logic [15:0] o_sr_din
);

    typedef logic [7:0] label_t [18];

    localparam logic [7:0] XF6 = 8'hf6;
    localparam logic [7:0] ASCII_PERIOD = 8'h2e;

    localparam label_t LABEL_PRESS_TO_START = "Press G16 to start";
    localparam label_t LABEL_WAIT           = "Wait green        ";
    localparam label_t LABEL_LATE           = "Late              ";
    localparam label_t LABEL_EARLY          = "Early             ";
    localparam label_t LABEL_DONE           = "Hit               ";
    localparam label_t LABEL_EMPTY          = {XF6,XF6,XF6,XF6,XF6,
                                               XF6,XF6,XF6,XF6,XF6,
                                               XF6,XF6,XF6,XF6,XF6,
                                               XF6,XF6,XF6};

    localparam logic [7:0] LABEL_LAST   [6]  = "Last: ";
    localparam logic [7:0] LABEL_BEST   [6]  = "Best: ";
    localparam logic [7:0] LABEL_PRNG   [6]  = "PRNG: ";
    localparam logic [7:0] LABEL_UNITS  [19] = "     s ms  \xbbs  ns ";
    localparam logic [7:0] LABEL_AUTHOR [17] = "Author: @limpix31";

    logic en_sync, en, en_d;
    logic bcd_load, bcd_valid_last, bcd_valid_best;
    logic bcd_valid;
    logic lit;
    logic [2:0] reaction_state;
    logic [3:0] lit_color;
    logic [7:0] label_color;

    logic [7:0] addr_cnt;

    logic last_untracked, best_untracked;

    logic [3:0] bcd_last [9];
    logic [3:0] bcd_best [9];

    logic [7:0] last_display [13];
    logic [7:0] best_display [13];

    logic [7:0] status_label [18];

    enum logic [3:0]
    { INIT
    , BACKGROUND
    , WAIT_BCD
    , LAST_LABEL
    , LAST_RESULT
    , BEST_LABEL
    , BEST_RESULT
    , UNITS
    , STATUS_LABEL
    , PRNG_LABEL
    , DBG_RND
    , AUTHOR
    , DONE
    } state;

    assign bcd_valid   = bcd_valid_last & bcd_valid_best;
    assign label_color = lit ? {4'h0, lit_color} : {4'hf, 4'h0};

    function static logic [7:0] to_ascii (logic [3:0] x);
        to_ascii = 8'h30 + 8'(x);
    endfunction

    typedef logic [7:0] result_display_t [13];

    function static result_display_t bcd_display (logic [3:0] bcd [9]);
        bcd_display[0]  = to_ascii(bcd[8]);
        bcd_display[1]  = ASCII_PERIOD;
        bcd_display[2]  = to_ascii(bcd[7]);
        bcd_display[3]  = to_ascii(bcd[6]);
        bcd_display[4]  = to_ascii(bcd[5]);
        bcd_display[5]  = ASCII_PERIOD;
        bcd_display[6]  = to_ascii(bcd[4]);
        bcd_display[7]  = to_ascii(bcd[3]);
        bcd_display[8]  = to_ascii(bcd[2]);
        bcd_display[9]  = ASCII_PERIOD;
        bcd_display[10] = to_ascii(bcd[1]);
        bcd_display[11] = to_ascii(bcd[0]);
        bcd_display[12] = to_ascii(0);
    endfunction

    always_comb begin
        last_display = bcd_display(bcd_last);
        best_display = bcd_display(bcd_best);
    end

    always_comb begin
        case (reaction_state)
            3'b001:  status_label = LABEL_WAIT;
            3'b010:  status_label = LABEL_EMPTY;
            3'b011:  status_label = LABEL_LATE;
            3'b110:  status_label = LABEL_EARLY;
            3'b100:  status_label = LABEL_DONE;
            default: status_label = LABEL_PRESS_TO_START;
        endcase
    end

    always_ff @(posedge i_clk) begin
        en_sync <= i_offscreen;
        en <= en_sync;
        en_d <= en;
    end

    always_ff @(posedge i_clk) begin
        if (en_d & ~en) begin
            state <= INIT;
        end else begin
            case (state)
                INIT: begin
                    bcd_load <= 1'b1;
                    reaction_state <= i_reaction_state;
                    last_untracked <= &i_last_result;
                    best_untracked <= &i_best_result;
                    o_sr_we <= 1'b1;
                    state <= BACKGROUND;
                end
                BACKGROUND: begin
                    bcd_load <= 1'b0;
                    o_sr_waddr <= ADDR_BACKGROUND;

                    case (reaction_state)
                        3'b010: begin
                            lit_color <= 4'h2;
                            lit <= 1'b1;
                            o_sr_din <= {8'h00, 4'h0, 4'h2};
                        end
                        3'b011, 3'b110: begin
                            lit_color <= 4'h1;
                            lit <= 1'b1;
                            o_sr_din <= {8'h00, 4'h0, 4'h1};
                        end
                        default: begin
                            lit_color <= 4'h0;
                            lit <= 1'b0;
                            o_sr_din <= {8'h00, 4'h0, 4'h0};
                        end
                    endcase

                    state <= WAIT_BCD;
                end
                WAIT_BCD: if (bcd_valid) begin
                    addr_cnt <= 0;
                    state <= LAST_LABEL;
                end
                LAST_LABEL: begin
                    o_sr_waddr <= ADDR_LABEL_LAST + 10'(addr_cnt);
                    o_sr_din   <= {LABEL_LAST[addr_cnt], label_color};

                    if (addr_cnt == 8'd5) begin
                        addr_cnt <= 0;
                        state    <= LAST_RESULT;
                    end else begin
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                LAST_RESULT: begin
                    o_sr_waddr <= ADDR_LAST_RESULT + 10'(addr_cnt);
                    o_sr_din <= {
                        last_untracked
                            ? 8'hf6
                            : last_display[addr_cnt],
                        label_color
                    };

                    if (addr_cnt == 8'd12) begin
                        addr_cnt <= 0;
                        state <= BEST_LABEL;
                    end else begin
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                BEST_LABEL: begin
                    o_sr_waddr <= ADDR_LABEL_BEST + 10'(addr_cnt);
                    o_sr_din   <= {LABEL_BEST[addr_cnt], label_color};

                    if (addr_cnt == 8'd5) begin
                        addr_cnt <= 0;
                        state    <= BEST_RESULT;
                    end else begin
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                BEST_RESULT: begin
                    o_sr_waddr <= ADDR_BEST_RESULT + 10'(addr_cnt);
                    o_sr_din <= {
                        best_untracked
                            ? 8'hf6
                            : best_display[addr_cnt],
                        label_color
                    };

                    if (addr_cnt == 8'd12) begin
                        addr_cnt <= 0;
                        state    <= UNITS;
                    end else begin
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                UNITS: begin
                    o_sr_waddr <= ADDR_UNITS + 10'(addr_cnt);
                    o_sr_din  <= {LABEL_UNITS[addr_cnt], label_color};

                    if (addr_cnt == 8'd18) begin
                        addr_cnt <= 0;
                        state    <= STATUS_LABEL;
                    end else begin
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                STATUS_LABEL: begin
                    o_sr_waddr <= ADDR_STATUS_LABEL + 10'(addr_cnt);
                    o_sr_din <= {status_label[addr_cnt], label_color};

                    if (addr_cnt == 8'd17) begin
                        addr_cnt <= 0;
                        state <= PRNG_LABEL;
                    end else begin
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                PRNG_LABEL: begin
                    o_sr_waddr <= ADDR_LABEL_PRNG + 10'(addr_cnt);
                    o_sr_din   <= {LABEL_PRNG[addr_cnt], label_color};

                    if (addr_cnt == 8'd5) begin
                        addr_cnt <= 0;
                        state    <= DBG_RND;
                    end else begin
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                DBG_RND: begin
                    o_sr_waddr <= ADDR_DBG_RND;
                    o_sr_din   <= i_dbg_rnd;
                    state      <= AUTHOR;
                end
                AUTHOR: begin
                    o_sr_waddr <= ADDR_AUTHOR + 10'(addr_cnt);

                    if (addr_cnt == 8'd17) begin
                        addr_cnt <= 0;
                        state    <= DONE;
                    end else if (addr_cnt > 8'd8) begin
                        o_sr_din <= {LABEL_AUTHOR[addr_cnt], lit ? {4'h0, lit_color} : {4'(addr_cnt) - 4'd8, 4'h0}};
                        addr_cnt <= addr_cnt + 8'd1;
                    end else begin
                        o_sr_din <= {LABEL_AUTHOR[addr_cnt], label_color};
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                DONE: begin
                    o_sr_we <= 1'b0;
                end
                default: begin
                    // Latch until the next offscreen time
                end
            endcase
        end
    end

    bin_to_bcd #
    ( .WIDTH(29)
    ) u_bcd_last
    ( .i_clk(i_clk)
    , .i_load(bcd_load)
    , .o_valid(bcd_valid_last)
    , .i_bin({i_last_result, 1'b0})
    , .o_bcd(bcd_last)
    );

    bin_to_bcd #
    ( .WIDTH(29)
    ) u_bcd_best
    ( .i_clk(i_clk)
    , .i_load(bcd_load)
    , .o_valid(bcd_valid_best)
    , .i_bin({i_best_result, 1'b0})
    , .o_bcd(bcd_best)
    );

endmodule : state_transfer

module ui_layout
    import ui::*;
( input  logic [8:0] i_bx
, input  logic [8:0] i_by

, output logic [9:0] o_addr
);

    always_comb begin
        if (i_by == 9'd20 && i_bx >= 9'd40 && i_bx < 9'd58) begin
            o_addr = ADDR_STATUS_LABEL + 10'(i_bx - 9'd40);
        end else if (i_by == 9'd25 && i_bx >= 9'd40 && i_bx < 9'd59) begin
            o_addr = ADDR_LABEL_LAST + 10'(i_bx - 9'd40);
        end else if (i_by == 9'd26 && i_bx >= 9'd40 && i_bx < 9'd59) begin
            o_addr = ADDR_LABEL_BEST + 10'(i_bx - 9'd40);
        end else if (i_by == 9'd27 && i_bx >= 9'd40 && i_bx < 9'd59) begin
            o_addr = ADDR_UNITS + 10'(i_bx - 9'd40);
        end else if (i_by == 9'd50 && i_bx >= 9'd40 && i_bx < 9'd47) begin
            o_addr = ADDR_LABEL_PRNG + 10'(i_bx - 9'd40);
        end else if (i_by == 9'd52 && i_bx >= 9'd40 && i_bx < 9'd57) begin
            o_addr = ADDR_AUTHOR + 10'(i_bx - 9'd40);
        end else begin
            o_addr = ADDR_BACKGROUND;
        end
    end

endmodule : ui_layout

module bin_to_bcd #
( parameter int WIDTH = 28
, parameter int DIGITS = int'($ceil($log10(2.0) * WIDTH))
)
( input logic i_clk

, input  logic i_load
, output logic o_valid

, input  logic [WIDTH-1:0] i_bin
, output logic [3:0]       o_bcd [DIGITS]
);

    localparam int BCD_WIDTH = DIGITS * 4;
    localparam int SHR_WIDTH = BCD_WIDTH + WIDTH;

    logic [SHR_WIDTH-1:0] shr;
    logic [SHR_WIDTH-1:0] next;
    logic [$clog2(WIDTH)-1:0] shifts;

    generate
        for (genvar i = 0; i < DIGITS; i++) begin : gen_bcd_assign
          assign o_bcd[i] = shr[ WIDTH + i*4 +: 4 ];
        end
    endgenerate

    assign o_valid = (shifts == WIDTH);

    always_comb begin
        for (int i = 0; i < DIGITS; i++) begin
            next[WIDTH + i*4 +: 4] =
                shr[WIDTH + i*4 +: 4] + (
                    shr[WIDTH + i*4 +: 4] >= 5 ? 4'd3 : 4'd0
                );
        end

        next[WIDTH-1:0] = shr[WIDTH-1:0];
    end

    always_ff @(posedge i_clk) begin
        if (i_load) begin
            shr    <= {{BCD_WIDTH{1'b0}}, i_bin};
            shifts <= 'd0;
        end else if (shifts < WIDTH) begin
            shr    <= next << 1;
            shifts <= shifts + 1;
        end
    end

endmodule : bin_to_bcd
