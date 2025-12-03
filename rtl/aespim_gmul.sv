module aespim_gmul (
    input logic [31:0] A,
    input logic [31:0] B,
    input logic [2:0]  S,
    output logic [31:0] C0,
    output logic [31:0] C1,
    output logic [7:0] C3
);
    logic [63:0] P;
    aespim_clmul32 u_clmul32 (
        .a(A),
        .b(B),
        .res(P)
    );

    // Reduction modulo x^32 + x^17 + x^15 + x^14 + 1
    aespim_reduce_shift u_reduce_shift (
        .product  (P),
        .shift_idx(S),
        .C0      (C0),
        .C1      (C1),
        .C3      (C3)
    );

endmodule
