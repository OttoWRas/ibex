// Simple testbench for aespim accelerator

module tb_aespim_accelerator;

  // Clock / reset
  reg         clk;
  reg         rst_n;

  // DUT signals
  reg         start_i;
  reg  [ 2:0] op_code_i;
  reg  [31:0] data_in_i;
  wire [31:0] data_out_o;
  wire        done_o;

  logic [31:0] data_in_vec [4] = '{32'hDEAD_BEEF, 32'hDECA_FBAD, 32'hF005_BA11, 32'h09cf4f3c};
  int i_to_j [4] = '{3, 0, 1, 2};
  // Clock generation: 100MHz (10ns period)
  initial begin
    clk = 0;
  end
  always #5 clk = ~clk;

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
      .op_code_i (op_code_i),
      .data_in_i (data_in_i),
      .data_out_o(data_out_o),
      .done_o    (done_o)
  );
  // Simple stimulus / probe (drive the DUT)
  initial begin
    $display("[%0t] Testbench started", $time);
    // Wait for reset to release
    wait (rst_n == 1);

    // Initialize DUT inputs
    start_i   = 1'b0;
    op_code_i = 3'b000;
    data_in_i = 32'h0000_0000;

    // Allow a few cycles to settle
    repeat (5) @(posedge clk);

    // 1) OP_LD: present data and pulse start to load into accelerator
    for (int i = 0; i < 4; i++) begin
      op_code_i = 3'b000;  // OP_LD
      data_in_i = data_in_vec[i_to_j[i]];
      start_i = 1'b1;
      @(posedge clk);
      $display("[%0t] OP_LD issued, data_in=0x%08h", $time, data_in_i);
    end

    start_i = 1'b0;
    @(posedge clk);

    op_code_i = 3'b010;  // OP_KEX
    data_in_i = 32'h0000_0000;
    $display("[%0t] OP_KEXR issued", $time);
    @(posedge clk);
    start_i = 1'b1;
    @(posedge clk);

    repeat (4) begin
      // 2) OP_KEX: request key expansion
      op_code_i = 3'b011;  // OP_KEX
      data_in_i = 32'h0000_0000;
      @(posedge clk);
      start_i = 1'b1;
      $display("[%0t] OP_KEX issued", $time);
    end

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
