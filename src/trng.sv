module trng_ring
( input  var logic clk
, output var logic o
);

    logic l0, l1, l2;

    LUT2 #(4'b0001) u_lut_0
    ( .F(l0), .I0(l2), .I1(1'b0) );

    LUT2 #(4'b0001) u_lut_1
    ( .F(l1), .I0(l0), .I1(1'b0) );

    LUT2 #(4'b0001) u_lut_2
    ( .F(l2), .I0(l1), .I1(1'b0) );

    always_ff @(posedge clk)
        o <= l2;

endmodule : trng_ring

module trng_hub #
( parameter int unsigned N = 3
)
( input  var logic clk
, output var logic out
);

    logic [N-1:0] r;
    logic xored;

    always_comb begin
        xored = 0;

        for (int i = 0; i < N; i++) begin
            xored = xored ^ r[i];
        end
    end

    always_ff @(posedge clk)
        out <= xored;

    generate
        for (genvar i = 0; i < N; i++) begin : gen_rings
            trng_ring u_ring (clk, r[i]);
        end
    endgenerate

endmodule : trng_hub

module trng #
( parameter int unsigned N = 16
, parameter int unsigned RINGS = 3
)
( input  var logic clk

, output var logic [N-1:0] out
);

    logic [N-1:0] rnd;
    logic [$clog2(N)-1:0] cnt;

    logic r;

    always_ff @(posedge clk) begin
        if (cnt == N - 1) begin
            cnt <= 0;
            out <= rnd;
        end else begin
            rnd <= {rnd[N-2:0], r};
            cnt <= cnt + '1;
        end
    end

    trng_hub #(RINGS) u_hub (clk, r);

endmodule : trng
