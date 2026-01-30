`define M_DEBUG
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNDRIVEN */

module aespim_reduce_shift (
    input  logic  [63:0]  product,
    input  logic  [2:0]   shift_idx,   // 0..6 -> shift by 0,32,64,...,192
    output logic  [31:0]  C0,
    output logic  [31:0]  C1,
    output logic  [7:0]   C3
);

    import aespim_pkg::CLMUL32_BASIS;

    logic [31:0] P_low  = product[31:0];
    logic [31:0] P_high = product[63:32];
    logic [39:0] P_high_reduced, P_low_reduced;
    logic [39:0]  P_high_double_reduced;

    // Reduction modulo x^32 + x^17 + x^15 + x^14 + 1
    logic [39:0] lo_acc;
    logic [39:0] hi_acc;
    logic [39:0] dhi_acc;

    always_comb begin
        // temporary accumulators

        lo_acc  = 0;
        hi_acc  = 0;
        dhi_acc = 0;

        for (int i = 0; i < 32; i++) begin
            if (P_low[i]) begin
                lo_acc[i]    ^= 1'b1;
                lo_acc[i+1]  ^= 1'b1;
                lo_acc[i+2]  ^= 1'b1;
                lo_acc[i+7]  ^= 1'b1;
            end
            if (P_high[i]) begin
                hi_acc[i]    ^= 1'b1;
                hi_acc[i+1]  ^= 1'b1;
                hi_acc[i+2]  ^= 1'b1;
                hi_acc[i+7]  ^= 1'b1;
            end
        end

        for (int i = 0; i < 8; i++) begin
            if (hi_acc[32 + i]) begin
                dhi_acc[i]    ^= 1'b1;
                dhi_acc[i+1]  ^= 1'b1;
                dhi_acc[i+2]  ^= 1'b1;
                dhi_acc[i+7]  ^= 1'b1;
            end
        end

        // update outputs *after* accumulation
        P_low_reduced          = lo_acc;
        P_high_reduced         = hi_acc;
        P_high_double_reduced  = dhi_acc;
    end

    always_comb begin
        C0 = 32'd0;
        C1 = 32'd0;
        C3 = 8'd0;
        unique case (shift_idx)
            0, 1, 2: begin : gen_no_reduce_shift
                C0 = P_low;
                C1 = P_high;
                C3 = 8'd0;
            end

            3 : begin : gen_partly_reduce_shift
                C0 = P_low[31:0];
                C1 = P_high_reduced[31:0];
                C3 = P_high_reduced[39:32];
            end

            4, 5: begin : gen_reduce_shift
                C0 = P_low_reduced[31:0];
                C1 = P_high_reduced[31:0] ^ {24'd0, P_low_reduced[39:32]};
                C3 = P_high_reduced[39:32];
            end

            6: begin : gen_fully_reduce_shift
                C0 = P_low_reduced[31:0] ^ {24'd0, P_high_double_reduced[7:0]};
                C1 = P_high_reduced[31:0] ^ {24'd0, P_low_reduced[39:32]};
            end

        endcase
    end

endmodule
// verilator lint_on UNUSEDSIGNAL
