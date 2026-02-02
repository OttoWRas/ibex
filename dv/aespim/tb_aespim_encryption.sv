// Simple testbench for aespim accelerator

module tb_aespim_encryption;

  // Clock / reset
  reg         clk;
  reg         rst_n;

  // DUT signals
  reg         start_i;
  reg  [ 4:0] op_code_i;
  reg  [31:0] data_in_i;
  wire [31:0] data_out_o;
  wire        done_o;

  //logic [3:0][31:0] key_vec [] =
 //{{{32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000}}};

  logic [3:0][31:0] key_vec [] =
 {{{32'h2b7e1516, 32'h28aed2a6, 32'habf71588, 32'h09cf4f3c}},
  {{32'ha0fafe17, 32'h88542cb1, 32'h23a33939, 32'h2a6c7605}},
  {{32'hf2c295f2, 32'h7a96b943, 32'h5935807a, 32'h7359f67f}},
  {{32'h3d80477d, 32'h4716fe3e, 32'h1e237e44, 32'h6d7a883b}},
  {{32'hef44a541, 32'ha8525b7f, 32'hb671253b, 32'hdb0bad00}},
  {{32'hd4d1c6f8, 32'h7c839d87, 32'hcaf2b8bc, 32'h11f915bc}},
  {{32'h6d88a37a, 32'h110b3efd, 32'hdbf98641, 32'hca0093fd}},
  {{32'h4e54f70e, 32'h5f5fc9f3, 32'h84a64fb2, 32'h4ea6dc4f}},
  {{32'head27321, 32'hb58dbad2, 32'h312bf560, 32'h7f8d292f}},
  {{32'hac7766f3, 32'h19fadc21, 32'h28d12941, 32'h575c006e}},
  {{32'hd014f9a8, 32'hc9ee2589, 32'he13f0cc8, 32'hb6630ca6}},
  {{32'h47eadde6, 32'h8e04f86f, 32'h6f3bf4a7, 32'hd958f801}}};

  //logic [3:0][31:0] state_vec = '{32'hD3D2D1D0, 32'hC3C2C1C0, 32'hB3B2B1B0, 32'hA3A2A1A0};
  logic [3:0][31:0] state_vec = '{32'h3243_f6a8, 32'h885a_308d, 32'h3131_98a2, 32'he037_0734};

  logic [3:0][31:0] result_vec = '{32'h3925_841d, 32'h02dc_09fb, 32'hdc11_8597, 32'h196a_0b32};
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
      .clk_i     (clk),
      .rst_ni    (rst_n),
      .start_i   (start_i),
      .op_code_i ({1'b0, op_code_i}),
      .data_in_mem_i (data_in_i),
      .data_in_reg_i (),
      .data_out_o(data_out_o)
  );
  // Simple stimulus / probe (drive the DUT)
  initial begin
    $display("[%0t] Testbench started", $time);
    // Wait for reset to release
    wait (rst_n == 1);

    // Initialize DUT inputs
    start_i   = 1'b0;
    op_code_i = 5'b00000;
    data_in_i = 32'h0000_0000;

    // Allow a few cycles to settle
    repeat (5) @(posedge clk);

    for (int i = 0; i < 4; i++) begin
      #2ns;
      op_code_i = 5'b00000;  // OP_LD
      data_in_i = state_vec[i];
      start_i = 1'b1;
      @(posedge clk);
    end
    $display("[%0t] OP_LD issued", $time);

    for (int i = 0; i < 4; i++) begin
      #2ns;
      op_code_i = {i[1:0], 3'b100};  // OP_ENCI
      data_in_i = key_vec[0][i];
      start_i = 1'b1;
      @(posedge clk);
    end
    $display("[%0t] OP_ENCI issued", $time);

    for (int i = 1; i < 10; i++) begin
      for (int j = 0; j < 4; j++) begin
        #2ns;
        op_code_i = {j[1:0], 3'b101};  // OP_ENCM
        data_in_i = key_vec[i][j];
        start_i = 1'b1;
        #2ns;
        @(posedge clk);
      end
    end
    $display("[%0t] OP_ENCM issued", $time);

    for (int j = 0; j < 4; j++) begin
      // 2) OP_KEX: request key expansion
      #2ns;
      op_code_i = {5'b00110};  // OP_ENCF
      data_in_i = key_vec[10][j];
      start_i = 1'b1;
      @(posedge clk);
    end
    $display("[%0t] OP_ENCF issued", $time);

    for (int i = 0; i < 4; i++) begin
      #2ns;
      op_code_i = 5'b00001;  // OP_ST
      data_in_i = 32'h0000_0000;
      start_i = 1'b1;
      @(posedge clk);
      assert (data_out_o == result_vec[i]) else
        $error("Mismatch at output %0d: expected 0x%08h, got 0x%08h", i, result_vec[i], data_out_o);
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
