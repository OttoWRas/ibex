
module aespim_accelerator (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  logic                  start_i,
    input  logic [3:0]            op_code_i,
    input  logic [31:0]           data_in_i,
    output logic [31:0]           data_out_o,
    output logic                  done_o
);

    typedef enum logic [3:0] {
        OP_LD  = 4'b0000,
        OP_ST  = 4'b0001,
        OP_KEX = 4'b0010
    } op_code_e;

    logic [7:0][3:0] C_q [4];
    logic [7:0][3:0] C_d [4];

    always_comb begin

        data_out_o = 32'd0;
        for (int i = 0; i < 4; i++) begin
            C_d[i] = C_q[i];
        end

        case(op_code_i)
            OP_LD: begin
                C_d[3] = data_in_i;
                C_d[2] = C_q[3];
                C_d[1] = C_q[2];
                C_d[0] = C_q[1];
            end
            OP_ST: begin
                C_d[3]     = 32'd0;
                C_d[2]     = C_q[3];
                C_d[1]     = C_q[2];
                C_d[0]     = C_q[1];
                data_out_o = C_q[0];
            end
            OP_KEX: begin
                // Key expansion logic
            end
            default: begin
                // Default case logic
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Reset logic
            done_o <= 1'b0;
        end else begin
            // Sequential logic
            for (int i = 0; i < 4; i++) begin
                C_q[i] <= C_d[i];
            end
        end
    end

endmodule