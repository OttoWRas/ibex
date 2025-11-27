module reduce_shift_gf128 (
    input  logic  [63:0]  product,
    input  logic  [2:0]   shift_idx,   // 0..6 -> shift by 0,32,64,...,192
    output logic  [31:0]  C0,
    output logic  [31:0]  C1,
    output logic  [5:0]   C3
);

    import aespim_pkg::CLMUL32_BASIS;

    logic [31:0] P_low  = product[31:0];
    logic [31:0] P_high = product[63:32];
    logic [39:0] P_high_reduced, P_low_reduced, P_high_double_reduced;

    // Reduction modulo x^32 + x^17 + x^15 + x^14 + 1

    always_comb begin
        for (int i = 0; i < 32; i = i + 1) begin
            P_high_reduced ^= {$bits(CLMUL32_BASIS[0]){P_high[i]}} & CLMUL32_BASIS[i];
            P_low_reduced  ^= {$bits(CLMUL32_BASIS[0]){P_low[i]}}  & CLMUL32_BASIS[i];
            P_high_double_reduced ^= {$bits(CLMUL32_BASIS[0]){P_high_reduced[i]}} & CLMUL32_BASIS[i];
        end
    end

    always_comb begin
        unique case (shift_idx)
            0, 1, 2: begin : gen_no_reduce_shift
                C0 = P_low;
                C1 = P_high;
                C3 = 7'd0;
            end

            3 : begin : gen_partly_reduce_shift
                C0 = P_low[31:0];
                C1 = P_high_reduced[31:0];
                C3 = P_high_reduced[39:32];
            end

            4, 5: begin : gen_reduce_shift
                C0 = P_low_reduced[31:0];
                C1 = P_high_reduced[31:0] ^ P_low_reduced[39:8];
                C3 = P_high_reduced[39:32];
            end

            6: begin : gen_fully_reduce_shift
                C0 = P_low_reduced[31:0];
                C1 = P_high_reduced[31:0] ^ P_low_reduced[39:8];
                C3 = P_high_double_reduced[7:0];
            end

        endcase
    end


endmodule
