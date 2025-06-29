module top
( input logic i_rst_n
, input logic i_clk_50m

, input logic i_btn_n

, output logic       o_hdmi_clk_p
, output logic       o_hdmi_clk_n
, output logic [2:0] o_hdmi_chan_p
, output logic [2:0] o_hdmi_chan_n
);

    // HDMI Clocks
    logic pll_lock;
    logic hdmi_pclk, hdmi_sclk;

    // Display Timings
    logic offscreen;
    logic [11:0] px [2], py [2];
    logic [8:0] bx, by;
    logic hs, vs, de;
    logic [23:0] video;

    logic [2:0][9:0] chan_vec;

    // Reaction time measurement
    logic [2:0]  reaction_state;
    logic [27:0] measured_ticks;
    logic [27:0] last_result;
    logic [27:0] best_result;

    logic [15:0] dbg_rnd;

    // State CDC
    logic sr_we;
    logic [9:0] sr_waddr, sr_raddr;
    logic [15:0] sr_din, sr_dout;

    // Latch the last and best results
    always_ff @(posedge i_clk_50m) begin
        if (!i_rst_n) begin
            last_result <= {28{1'b1}};
            best_result <= {28{1'b1}};
        end else if (reaction_state == 3'b100) begin
            last_result <= measured_ticks;
            best_result <= measured_ticks < best_result ? measured_ticks : best_result;
        end
    end

    always_ff @(posedge hdmi_pclk) begin
        px[1] <= px[0];
        py[1] <= py[0];
    end

    hclk u_hclk
    ( .i_clk_50m(i_clk_50m)
    , .o_lock(pll_lock)
    , .o_pclk(hdmi_pclk)
    , .o_sclk(hdmi_sclk)
    );

    timing_source u_tso
    ( .i_pclk(hdmi_pclk)
    , .i_rst(~i_rst_n)
    , .o_px(px[0])
    , .o_py(py[0])
    , .o_bx(bx)
    , .o_by(by)
    , .o_offscreen(offscreen)
    );

    reaction u_reaction
    ( .i_clk_50m(i_clk_50m)
    , .i_rst(~i_rst_n)
    , .i_btn_n(i_btn_n)
    , .o_state(reaction_state)
    , .o_ticks(measured_ticks)
    , .o_dbg_rnd(dbg_rnd)
    );

    state_ram u_sr
    ( .i_wclk(i_clk_50m)
    , .i_rclk(hdmi_pclk)
    , .i_we(sr_we)
    , .i_waddr(sr_waddr)
    , .i_raddr(sr_raddr)
    , .i_din(sr_din)
    , .o_dout(sr_dout)
    );

    state_transfer u_state
    ( .i_uclk(i_clk_50m)
    , .i_pclk(hdmi_pclk)
    , .i_offscreen(offscreen)
    , .i_reaction_state(reaction_state)
    , .i_last_result(last_result)
    , .i_best_result(best_result)
    , .i_dbg_rnd(dbg_rnd)
    , .o_sr_we(sr_we)
    , .o_sr_waddr(sr_waddr)
    , .o_sr_din(sr_din)
    );

    ui_layout u_layout
    ( .i_bx(bx)
    , .i_by(by)
    , .o_addr(sr_raddr)
    );

    renderer u_renderer
    ( .i_pclk(hdmi_pclk)
    , .i_char(sr_dout)
    , .i_x(px[1])
    , .i_y(py[1])
    , .o_hs(hs)
    , .o_vs(vs)
    , .o_de(de)
    , .o_video(video)
    );

    hvtx_mod u_mod
    ( .i_pixel_clk(hdmi_pclk)
    , .i_serial_clk(hdmi_sclk)
    , .i_hs(hs)
    , .i_vs(vs)
    , .i_de(de)
    , .i_video(video)
    , .o_chan_vec(chan_vec)
    );

    hvtx_ser u_ser_a
    ( .i_pixel_clk(hdmi_pclk)
    , .i_serial_clk(hdmi_sclk)
    , .i_rst(~i_rst_n)
    , .i_chan_vec(chan_vec)
    , .o_hdmi_clk_p(o_hdmi_clk_p)
    , .o_hdmi_clk_n(o_hdmi_clk_n)
    , .o_hdmi_chan_p(o_hdmi_chan_p)
    , .o_hdmi_chan_n(o_hdmi_chan_n)
    );

endmodule : top
