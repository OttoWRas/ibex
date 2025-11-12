package aespim_pkg;

    typedef enum logic [2:0] {
        OP_LD   = 3'b000,
        OP_ST   = 3'b001,
        OP_KEXI = 3'b010,
        OP_KEX  = 3'b011,
        OP_ENCI = 3'b100,
        OP_ENCM = 3'b101,
        OP_ENCF = 3'b110,
        OP_DECM = 3'b111
    } op_code_e;

    function automatic [3:0][7:0] aespim_mixcolumn(input logic [3:0][7:0] state);
        logic [7:0] tmp;
        logic [3:0][7:0] MIX;

        tmp = state[0] ^ state[1] ^ state[2] ^ state[3];

        for (int i = 0; i < 4; i++) begin
            MIX[i] = {state[i][7:0] ^ state[(i-1)%4][7:0]}[7] ?
              (((state[i][7:0] ^ state[(i-1)%4][7:0]) << 1) ^ 8'h1b) :
              (((state[i][7:0] ^ state[(i-1)%4][7:0]) << 1));
        end

        return state ^ {4{tmp}} ^ MIX;
    endfunction;

    function automatic [3:0][7:0] aespim_inv_mixcolumn(input logic [3:0][7:0] state);
        logic [7:0] tmp, tmpMIX;
        logic [3:0][7:0] MIX;
        logic [3:0][7:0] MIX4;

        tmp = state[0] ^ state[1] ^ state[2] ^ state[3];

        for (int i = 0; i < 4; i++) begin
            MIX[i] = {state[i][7:0] ^ state[(i-1)%4][7:0]}[7] ?
              (state[i][7:0] ^ tmp ^ ((state[i][7:0] ^ state[(i-1)%4][7:0]) << 1) ^ 8'h1b) :
              (state[i][7:0] ^ tmp ^ ((state[i][7:0] ^ state[(i-1)%4][7:0]) << 1));
        end

        MIX4 = state;
        for (int j = 0; j < 2; j++) begin
            for (int i = 0; i < 4; i++) begin
                MIX4[i] = {((MIX4[i][7:0] ^ MIX4[(i-2)%4][7:0]) << 1) ^ 8'h1b}[7] ?
                  (((MIX4[i][7:0] ^ MIX4[(i-2)%4][7:0]) << 1) ^ 8'h1b) ^ 8'h1b :
                  (((MIX4[i][7:0] ^ MIX4[(i-2)%4][7:0]) << 1) ^ 8'h1b);
            end
        end

        tmpMIX = tmp;
        for (int i = 0; i < 3; i++) begin
            tmpMIX = tmpMIX[7] ? (tmpMIX << 1) ^ 8'h1b : (tmpMIX << 1);
        end

        return state ^ {4{tmp}} ^ MIX ^ {4{tmpMIX}} ^ MIX4;
    endfunction;

endpackage
