// Simple testbench for aespim accelerator

module tb_aespim_gmul;

  import aespim_pkg::*;

  // Clock / reset
  reg         clk;
  reg         rst_n;

  // DUT signals
  reg         start_i;
  reg  [ 5:0] op_code_i;
  reg  [31:0] data_in_mem_i, data_in_reg_i;
  wire [31:0] data_out_o;
  wire        done_o;

  //logic [3:0][31:0] key_vec [] =
 //{{{32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000}}};

  //66e94bd4ef8a2c3b884cfa59ca342b2e
  logic [3:0][31:0] A = '{32'h66e9_4bd4, 32'hef8a_2c3b, 32'h884c_fa59, 32'hca34_2b2e};

  //0388dace60b6a392f328c2b971b2fe78
  logic [3:0][31:0] B = '{32'h0388_dace, 32'h60b6_a392, 32'hf328_c2b9, 32'h71b2_fe78};

  //519fa38ac731568e9c1eb21731167f1c
  logic [3:0][31:0] C = '{32'h519f_a38a, 32'hc731_568e, 32'h9c1e_b217, 32'h3116_7f1c};

  localparam int BMAP [4][4] = '{'{0, 1, 2, 3},
                                 '{3, 0, 1, 2},
                                 '{2, 3, 0, 1},
                                 '{1, 2, 3, 0}};

  // Clock generation: 100MHz (10ns period)
  initial begin
    clk = 0;
  end
  always #5ns clk = ~clk;

  // Reset sequence
  initial begin
    rst_n = 0;
    #20;  // hold reset for a few cycles
    @(posedge clk);
    rst_n = 1;
    $display("[%0t] Reset released", $time);
  end

  // Instantiate DUT (connect signals)
  aespim_accelerator dut (
      .clk_i         (clk),
      .rst_ni        (rst_n),
      .start_i       (start_i),
      .op_code_i     (op_code_i),
      .data_in_mem_i (data_in_mem_i),
      .data_in_reg_i (data_in_reg_i),
      .data_out_o    (data_out_o)
  );
  // Simple stimulus / probe (drive the DUT)
  initial begin
    $display("[%0t] Testbench started", $time);
    // Wait for reset to release
    wait (rst_n == 1);

    // Initialize DUT inputs
    start_i   = 1'b0;
    op_code_i = 6'b000000;
    data_in_mem_i = 32'h0000_0000;
    data_in_reg_i = 32'h0000_0000;

    // Allow a few cycles to settle
    repeat (5) @(posedge clk);

    for (int i = 0; i < 4; i++) begin
      for (int j = 0; j < 4; j++) begin
        #2ns;
        op_code_i = {{i+BMAP[i][j]}[2:0], OP_GMUL};  // OP_GMUL
        data_in_reg_i = A[i];
        data_in_mem_i = B[BMAP[i][j]];
        start_i   = 1'b1;
        @(posedge clk);
      end
    end
    $display("[%0t] OP_GMUL issued", $time);

    for (int i = 0; i < 4; i++) begin
      #2ns;
      op_code_i     = {3'b000, OP_ST};  // OP_ST
      data_in_mem_i = 32'h0000_0000;
      data_in_reg_i = 32'h0000_0000;
      start_i = 1'b1;
      @(posedge clk);
      assert (data_out_o == C[i]) else
        $warning("Mismatch at output %0d: expected 0x%08h, got 0x%08h", i, C[i], data_out_o);
    end
    $display("[%0t] OP_ST issued", $time);

    start_i = 1'b0;
    @(posedge clk);

    // Wait some cycles for pipeline to update
    repeat (10) @(posedge clk);

    // Probe outputs
    $display("[%0t] data_out=0x%08h done=%0b", $time, data_out_o, done_o);

    $display("[%0t] Testbench finished", $time);
    $finish;
  end

  // Optional waveform dumping for simulation
  initial begin
    $dumpfile("tb_aespim_accelerator.vcd");
    $dumpvars(0, tb_aespim_accelerator);
  end

endmodule
