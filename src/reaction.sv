module reaction #
( parameter int COMPENSATION = 0
)
( input  logic i_clk_50m
, input  logic i_rst
, input  logic i_btn_n

, output logic [2:0]  o_state
, output logic [27:0] o_ticks

, output logic [15:0] o_dbg_rnd
);

    logic clicked;
    logic [27:0] cnt;
    logic [15:0] rnd;
    logic [27:0] target;
    logic [27:0] ticks;

    enum logic [2:0]
    { IDLE  = 3'b000
    , ARMED = 3'b001
    , LIT   = 3'b010
    , LATE  = 3'b011
    , EARLY = 3'b110
    , VALID = 3'b100
    } state;

    assign o_state = state;
    assign o_ticks = ticks;

    assign o_dbg_rnd = rnd;

    always_ff @(posedge i_clk_50m) begin
        if (i_rst) begin
            cnt   <= 'd0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: if (clicked) begin
                    cnt    <= 0;
                    target <= {2'b0, rnd, 10'b0};
                    state  <= ARMED;
                end
                ARMED: begin
                    if (cnt >= target) begin
                        cnt <= 'd0;
                        state <= LIT;
                    end else if (clicked) begin
                        state <= EARLY;
                    end else begin
                        cnt <= cnt + 28'd1;
                    end
                end
                LIT: begin
                    if (clicked) begin
                        ticks <= cnt - 28'(COMPENSATION);
                        cnt <= 0;
                        state <= VALID;
                    end else if (&cnt) begin
                        state <= LATE;
                    end else begin
                        cnt <= cnt + 28'd1;
                    end
                end
                LATE, EARLY, VALID: begin
                    if (cnt == 28'd50_000_000) begin
                        state <= IDLE;
                    end else begin
                        cnt <= cnt + 28'd1;
                    end
                end
                default: begin
                    // Do nothing
                end
            endcase
        end
    end

    debounce u_debounce
    ( .clk(i_clk_50m)
    , .i(~i_btn_n)
    , .o(clicked)
    );

    prng u_prng
    ( .i_clk(i_clk_50m)
    , .i_rst(i_rst)
    , .o_rnd(rnd)
    );

endmodule : reaction

module prng
( input  logic i_clk
, input  logic i_rst

, output logic [15:0] o_rnd
);

    logic [15:0] rnd;
    logic feedback;

    assign o_rnd = rnd;
    assign feedback = rnd[15] ^ rnd[13] ^ rnd[12] ^ rnd[10];

    always @(posedge i_clk) begin
        if (i_rst) begin
            rnd <= 16'hDEAD;
        end else begin
            rnd <= {rnd[14:0], feedback};
        end
    end

endmodule

module debounce
( input  logic clk
, input  logic i
, output logic o
);

    logic [15:0] cnt;

    always_ff @(posedge clk) begin
        if (i) begin
            if (&cnt) begin
                cnt <= 'd0;
                o   <= 1'b1;
            end else begin
                cnt <= cnt;
                o   <= 1'b0;
            end
        end else begin
            cnt <= &cnt ? cnt : cnt + 16'd1;
            o   <= 1'b0;
        end
    end

endmodule : debounce
