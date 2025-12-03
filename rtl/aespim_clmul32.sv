module aespim_clmul32 (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [63:0] res
);

    integer i;

    always_comb begin
        res = 64'b0;

        // for each bit of b: if bit is 1, XOR (a << i) into result
        for (i = 0; i < 32; i++) begin
            if (b[i]) begin
                res ^= ( {32'b0, a} << i );
            end
        end
    end

endmodule
