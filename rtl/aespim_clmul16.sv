module aespim_clmul16 (
    input  logic [15:0] a,
    input  logic [15:0] b,
    output logic [31:0] p
);

    logic [15:0] terms [32];

    genvar i, j;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_i
            for (j = 0; j < 16; j = j + 1) begin : gen_j
                if ((j <= i) && ((i - j) <= 15)) begin
                    assign terms[i][j] = a[j] & b[i-j];
                end else begin
                    assign terms[i][j] = 1'b0;
                end
            end
            assign p[i] = ^terms[i];  // XOR reduction of all valid terms
        end
    endgenerate

endmodule