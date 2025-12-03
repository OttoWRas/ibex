module aespim_accelerator (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  logic                  start_i,
    input  logic [5:0]            op_code_i,
    input  logic [3:0][7:0]       data_in_mem_i,
    input  logic [3:0][7:0]       data_in_reg_i,
    output logic [31:0]           data_out_o
);
    import aespim_pkg::*;

    localparam logic [7:0] GF8_4301 = 8'b00011011; // x^4 + x^3 + x + 1

    logic [2:0] op_code = op_code_i[2:0];
    logic [2:0] sr_code = op_code_i[5:3];

    // SBox instances and wiring
    logic sb_f;
    logic [3:0][7:0] sb_i, sb_o;
    generate
        for (genvar i = 0; i < 4; i++) begin : gen_sbox
            aespim_bSbox u_bSbox (
                .A      (sb_i[i]),
                .encrypt(sb_f),
                .Q      (sb_o[i])
            );
        end
    endgenerate

    // Rcon lookup table
    logic [7:0] Rcon [10] = '{8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80, 8'h1B, 8'h36};

    logic [3:0][7:0] C_q [4], C_d [4];
    logic [3:0][7:0] A;
    logic [3:0][7:0] B;
    logic [3:0][7:0] MIX;
    logic [2:0] SR;
    assign SR = sr_code;

    // GF Multiplier instance
    logic [31:0] gf_c0, gf_c1;
    logic [7:0]  gf_c3;
    aespim_gmul u_gmul (
        .A (data_in_mem_i),
        .B (data_in_reg_i),
        .S (SR),
        .C0(gf_c0),
        .C1(gf_c1),
        .C3(gf_c3)
    );

    logic [7:0] tmp;

    always_comb begin
        for (int i = 0; i < 4; i++) C_d[i] = C_q[i];
        A          = 32'd0;
        B          = 32'd0;
        MIX        = 32'd0;
        //SR         = sr_code;
        data_out_o = 32'd0;
        sb_i       = C_q[0];
        sb_f       = 1'b1;
        tmp        = 8'd0;

        case(op_code)
            OP_LD: begin
                A = data_in_mem_i;
            end

            OP_ST: begin
                A = C_q[0];
                data_out_o = C_q[0];
            end

            OP_KEXI: begin
                A = C_q[0];
                B = {sb_o[2],sb_o[1],sb_o[0],sb_o[3]} ^ {Rcon[0], 24'd0};
                data_out_o = C_q[0];
            end

            OP_KEX: begin
                A = C_q[0];
                B = C_q[0];
                data_out_o = C_q[0];
            end

            OP_ENCI: begin
                A = data_in_mem_i ^ C_q[0];
            end

            OP_ENCF: begin
                A = data_in_mem_i ^ sb_o;
            end

            OP_GMUL: begin
                A = C_d[0] ^ gf_c0;
                B = gf_c1;
                // Implement GF multiplication logic here
            end

            default: begin
                // Default case logic
            end
        endcase

        if (start_i) begin
            C_d[3]     = A;
            C_d[2]     = C_q[3];
            C_d[1]     = C_q[2];
            C_d[0]     = C_q[1] ^ B;
        end

        //Shift row operation
        case (op_code)
            OP_ENCI, OP_ENCM, OP_ENCF: begin
                for (int i = 1; i <= SR; i++) begin
                    //$display("[%0t] Shift Row A %0d, %0d %00h", $time, 3-i ,i-1, A[i-1]);
                    C_d[3-i][i-1] = A[i-1];
                    for (int j = 0; j < i; j++) begin
                        //$display("[%0t] Shift Row S %0d, %0d", $time, 3-j ,i-1);
                        C_d[3-j][i-1] = C_q[3-j][i-1];
                    end
                end
            end
            OP_GMUL: begin
                C_d[1] = C_q[2] ^ {24'd0, gf_c3};
            end
            default: ; // no shift
        endcase

    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 4; i++) C_q[i] <= 32'd0;
        end else begin
            for (int i = 0; i < 4; i++) C_q[i] <= C_d[i];
        end
    end

endmodule
