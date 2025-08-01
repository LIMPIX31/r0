module hclk
( input  var logic i_clk_50m
, output var logic o_lock
, output var logic o_sclk
, output var logic o_pclk
);

    logic pclk, sclk, lock;

    assign o_lock = lock;
    assign o_pclk = pclk;
    assign o_sclk = sclk;

    logic [8:0] unused;

    PLL #
    ( .FCLKIN("50")
    , .IDIV_SEL(1)
    , .FBDIV_SEL(1)
    , .ODIV0_SEL(2)
    , .ODIV1_SEL(8)
    , .ODIV2_SEL(8)
    , .ODIV3_SEL(8)
    , .ODIV4_SEL(8)
    , .ODIV5_SEL(8)
    , .ODIV6_SEL(8)
    , .MDIV_SEL(30)
    , .MDIV_FRAC_SEL(0)
    , .ODIV0_FRAC_SEL(0)
    , .CLKOUT0_EN("TRUE")
    , .CLKOUT1_EN("FALSE")
    , .CLKOUT2_EN("FALSE")
    , .CLKOUT3_EN("FALSE")
    , .CLKOUT4_EN("FALSE")
    , .CLKOUT5_EN("FALSE")
    , .CLKOUT6_EN("FALSE")
    , .CLKFB_SEL("INTERNAL")
    , .CLKOUT0_DT_DIR(1'b1)
    , .CLKOUT1_DT_DIR(1'b1)
    , .CLKOUT2_DT_DIR(1'b1)
    , .CLKOUT3_DT_DIR(1'b1)
    , .CLKOUT0_DT_STEP(0)
    , .CLKOUT1_DT_STEP(0)
    , .CLKOUT2_DT_STEP(0)
    , .CLKOUT3_DT_STEP(0)
    , .CLK0_IN_SEL(1'b0)
    , .CLK0_OUT_SEL(1'b0)
    , .CLK1_IN_SEL(1'b0)
    , .CLK1_OUT_SEL(1'b0)
    , .CLK2_IN_SEL(1'b0)
    , .CLK2_OUT_SEL(1'b0)
    , .CLK3_IN_SEL(1'b0)
    , .CLK3_OUT_SEL(1'b0)
    , .CLK4_IN_SEL(2'b00)
    , .CLK4_OUT_SEL(1'b0)
    , .CLK5_IN_SEL(1'b0)
    , .CLK5_OUT_SEL(1'b0)
    , .CLK6_IN_SEL(1'b0)
    , .CLK6_OUT_SEL(1'b0)
    , .DYN_DPA_EN("FALSE")
    , .CLKOUT0_PE_COARSE(0)
    , .CLKOUT0_PE_FINE(0)
    , .CLKOUT1_PE_COARSE(0)
    , .CLKOUT1_PE_FINE(0)
    , .CLKOUT2_PE_COARSE(0)
    , .CLKOUT2_PE_FINE(0)
    , .CLKOUT3_PE_COARSE(0)
    , .CLKOUT3_PE_FINE(0)
    , .CLKOUT4_PE_COARSE(0)
    , .CLKOUT4_PE_FINE(0)
    , .CLKOUT5_PE_COARSE(0)
    , .CLKOUT5_PE_FINE(0)
    , .CLKOUT6_PE_COARSE(0)
    , .CLKOUT6_PE_FINE(0)
    , .DYN_PE0_SEL("FALSE")
    , .DYN_PE1_SEL("FALSE")
    , .DYN_PE2_SEL("FALSE")
    , .DYN_PE3_SEL("FALSE")
    , .DYN_PE4_SEL("FALSE")
    , .DYN_PE5_SEL("FALSE")
    , .DYN_PE6_SEL("FALSE")
    , .DE0_EN("FALSE")
    , .DE1_EN("FALSE")
    , .DE2_EN("FALSE")
    , .DE3_EN("FALSE")
    , .DE4_EN("FALSE")
    , .DE5_EN("FALSE")
    , .DE6_EN("FALSE")
    , .RESET_I_EN("FALSE")
    , .RESET_O_EN("FALSE")
    , .ICP_SEL(6'bXXXXXX)
    , .LPF_RES(3'bXXX)
    , .LPF_CAP(2'b00)
    , .SSC_EN("FALSE")
    , .DYN_IDIV_SEL("FALSE")
    , .DYN_FBDIV_SEL("FALSE")
    , .DYN_MDIV_SEL("FALSE")
    , .DYN_ODIV0_SEL("FALSE")
    , .DYN_ODIV1_SEL("FALSE")
    , .DYN_ODIV2_SEL("FALSE")
    , .DYN_ODIV3_SEL("FALSE")
    , .DYN_ODIV4_SEL("FALSE")
    , .DYN_ODIV5_SEL("FALSE")
    , .DYN_ODIV6_SEL("FALSE")
    , .DYN_DT0_SEL("FALSE")
    , .DYN_DT1_SEL("FALSE")
    , .DYN_DT2_SEL("FALSE")
    , .DYN_DT3_SEL("FALSE")
    , .DYN_ICP_SEL("FALSE")
    , .DYN_LPF_SEL("FALSE")
    ) u_pll
    ( .LOCK(lock)
    , .CLKOUT0(sclk)
    , .CLKOUT1(unused[0])
    , .CLKOUT2(unused[1])
    , .CLKOUT3(unused[2])
    , .CLKOUT4(unused[3])
    , .CLKOUT5(unused[4])
    , .CLKOUT6(unused[5])
    , .CLKFBOUT(unused[6])
    , .CLKIN(i_clk_50m)
    , .CLKFB(1'b0)
    , .RESET(1'b0)
    , .PLLPWD(1'b0)
    , .RESET_I(1'b0)
    , .RESET_O(1'b0)
    , .FBDSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .IDSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .MDSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .MDSEL_FRAC({1'b0,1'b0,1'b0})
    , .ODSEL0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .ODSEL0_FRAC({1'b0,1'b0,1'b0})
    , .ODSEL1({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .ODSEL2({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .ODSEL3({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .ODSEL4({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .ODSEL5({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .ODSEL6({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .DT0({1'b0,1'b0,1'b0,1'b0})
    , .DT1({1'b0,1'b0,1'b0,1'b0})
    , .DT2({1'b0,1'b0,1'b0,1'b0})
    , .DT3({1'b0,1'b0,1'b0,1'b0})
    , .ICPSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .LPFRES({1'b0,1'b0,1'b0})
    , .LPFCAP({1'b0,1'b0})
    , .PSSEL({1'b0,1'b0,1'b0})
    , .PSDIR(1'b0)
    , .PSPULSE(1'b0)
    , .ENCLK0(1'b1)
    , .ENCLK1(1'b1)
    , .ENCLK2(1'b1)
    , .ENCLK3(1'b1)
    , .ENCLK4(1'b1)
    , .ENCLK5(1'b1)
    , .ENCLK6(1'b1)
    , .SSCPOL(1'b0)
    , .SSCON(1'b0)
    , .SSCMDSEL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    , .SSCMDSEL_FRAC({1'b0,1'b0,1'b0})
    );

    CLKDIV #
    ( .DIV_MODE("5")
    ) u_div_5
    ( .CLKOUT(pclk)
    , .HCLKIN(sclk)
    , .RESETN(1'b1)
    , .CALIB(1'b0)
    );

endmodule : hclk
