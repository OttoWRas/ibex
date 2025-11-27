// ===========================================================
// 32×32 Carry-less Multiplier using One-Level Karatsuba
// P = A * B in GF(2), no reduction (full 64-bit product)
// ===========================================================

module aespim_clmul32_karatsuba (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [63:0] p
);

    // Split into 16-bit halves
    logic [15:0] a_lo = a[15:0];
    logic [15:0] a_hi = a[31:16];
    logic [15:0] b_lo = b[15:0];
    logic [15:0] b_hi = b[31:16];

    // Compute U = a_lo ⊕ a_hi, V = b_lo ⊕ b_hi
    logic [15:0] u = a_lo ^ a_hi;
    logic [15:0] v = b_lo ^ b_hi;

    // Partial products (each 16×16 CLMUL → 32-bit)
    logic [31:0] p0;
    logic [31:0] p2;
    logic [31:0] p1_raw;

    aespim_clmul16 u_p0 (.a(a_lo), .b(b_lo), .p(p0));      // low * low
    aespim_clmul16 u_p2 (.a(a_hi), .b(b_hi), .p(p2));      // high * high
    aespim_clmul16 u_p1 (.a(u),    .b(v),    .p(p1_raw));  // (lo⊕hi)*(lo⊕hi)
    // Karatsuba middle term:
    // p1 = p1_raw ⊕ p0 ⊕ p2
    logic [31:0] p1 = p1_raw ^ p0 ^ p2;

    // Combine partial products:
    // Full product = p0 + (p1 << 16) + (p2 << 32)
    assign p =
        {32'd0, p0} ^                // p0
        ({16'd0, p1, 16'd0}) ^       // p1 << 16
        ({p2, 32'd0});               // p2 << 32

endmodule
