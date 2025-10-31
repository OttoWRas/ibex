module aespim_accelerator (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  logic                  start_i,
    input  logic [2:0]            op_code_i,
    input  logic [31:0]           data_in_i,
    output logic [31:0]           data_out_o,
    output logic                  done_o
);

    typedef enum logic [2:0] {
        OP_LD  = 3'b000,
        OP_ST  = 3'b001,
        OP_KEXR= 3'b010,
        OP_KEX = 3'b011
    } op_code_e;


    // SBox instances and wiring
    logic sb_f;
    logic [3:0][7:0] sb_i, sb_o;
    generate
        for (genvar i = 0; i < 4; i++) begin : gen_sbox
            bSbox u_bSbox (
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

    always_comb begin
        A          = 32'd0;
        B          = 32'd0;
        data_out_o = 32'd0;
        sb_i       = 32'd0;
        sb_f       = 1'b0;

        case(op_code_i)
            OP_LD: begin
                A = data_in_i[31:0];
                B = 32'd0;
            end

            OP_ST: begin
                data_out_o = C_q[0];
            end

            OP_KEXR: begin
                sb_i = C_q[0];
                sb_f = 1'b1;

                A = C_q[0];
                B = {sb_o[2],sb_o[1],sb_o[0],sb_o[3]} ^ {Rcon[0], 24'd0};

                data_out_o = C_q[0];
            end

            OP_KEX: begin
                sb_i = C_q[0];
                sb_f = 1'b1;

                A = C_q[0];
                B = C_q[0];

                data_out_o = C_q[0];
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
        end else begin
            for (int i = 0; i < 4; i++) C_d[i] = C_q[i];
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 4; i++) C_q[i] <= 32'd0;
        end else begin
            for (int i = 0; i < 4; i++) C_q[i] <= C_d[i];
        end
    end

endmodule
