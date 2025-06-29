package ui;

    localparam bit [9:0] ADDR_BACKGROUND   = 10'h00; // 0
    localparam bit [9:0] ADDR_LAST_RESULT  = 10'h01; // 10
    localparam bit [9:0] ADDR_BEST_RESULT  = 10'h0b; // 10
    localparam bit [9:0] ADDR_STATUS_LABEL = 10'h15; // 18
    localparam bit [9:0] ADDR_DBG_RND      = 10'h27; // 1

endpackage : ui

module state_ram
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
( input logic i_uclk
, input logic i_pclk
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

    localparam label_t LABEL_PRESS_TO_START = "Press G16 to start";
    localparam label_t LABEL_WAIT           = "Wait green        ";
    localparam label_t LABEL_LATE           = "Late              ";
    localparam label_t LABEL_EARLY          = "Early             ";
    localparam label_t LABEL_DONE           = "Hit               ";
    localparam label_t LABEL_EMPTY          = {XF6,XF6,XF6,XF6,XF6,
                                               XF6,XF6,XF6,XF6,XF6,
                                               XF6,XF6,XF6,XF6,XF6,
                                               XF6,XF6,XF6};

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

    logic [7:0] status_label [18];

    enum logic [3:0]
    { INIT
    , BACKGROUND
    , WAIT_BCD
    , LAST_RESULT
    , BEST_RESULT
    , LABEL
    , DBG_RND
    , DONE
    } state;

    assign bcd_valid   = bcd_valid_last & bcd_valid_best;
    assign label_color = lit ? {4'h0, lit_color} : {4'hf, 4'h0};

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

    always_ff @(posedge i_uclk) begin
        en_sync <= i_offscreen;
        en <= en_sync;
        en_d <= en;
    end

    always_ff @(posedge i_uclk) begin
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
                    state <= LAST_RESULT;
                end
                LAST_RESULT: begin
                    o_sr_waddr <= ADDR_LAST_RESULT + addr_cnt;

                    if (addr_cnt == 8'd9) begin
                        o_sr_din <= {8'hbb, label_color};
                        addr_cnt <= 0;
                        state <= BEST_RESULT;
                    end else begin
                        o_sr_din <= {
                            last_untracked
                                ? 8'hf6
                                : 8'h30 + bcd_last[8'd9 - addr_cnt],
                            label_color
                        };
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                BEST_RESULT: begin
                    o_sr_waddr <= ADDR_BEST_RESULT + addr_cnt;

                    if (addr_cnt == 8'd9) begin
                        o_sr_din <= {8'hbb, label_color};
                        addr_cnt <= 0;
                        state <= LABEL;
                    end else begin
                        o_sr_din <= {
                            best_untracked
                                ? 8'hf6
                                : 8'h30 + bcd_best[8'd9 - addr_cnt],
                            label_color
                        };
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                LABEL: begin
                    o_sr_waddr <= ADDR_STATUS_LABEL + addr_cnt;
                    o_sr_din <= {status_label[addr_cnt], label_color};

                    if (addr_cnt == 8'd17) begin
                        addr_cnt <= 0;
                        state <= DBG_RND;
                    end else begin
                        addr_cnt <= addr_cnt + 8'd1;
                    end
                end
                DBG_RND: begin
                    o_sr_waddr <= ADDR_DBG_RND;
                    o_sr_din   <= i_dbg_rnd;
                    state      <= DONE;
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
    ( .i_clk(i_uclk)
    , .i_load(bcd_load)
    , .o_valid(bcd_valid_last)
    , .i_bin({i_last_result, 1'b0})
    , .o_bcd(bcd_last)
    );

    bin_to_bcd #
    ( .WIDTH(29)
    ) u_bcd_best
    ( .i_clk(i_uclk)
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
        end else if (i_by == 9'd25 && i_bx >= 9'd40 && i_bx < 9'd50) begin
            o_addr = ADDR_LAST_RESULT + 10'(i_bx - 9'd40);
        end else if (i_by == 9'd26 && i_bx >= 9'd40 && i_bx < 9'd50) begin
            o_addr = ADDR_BEST_RESULT + 10'(i_bx - 9'd40);
        end else if (i_by == 9'd50 && i_bx == 9'd40) begin
            o_addr = ADDR_DBG_RND;
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
