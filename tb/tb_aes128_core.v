// tb_aes128_core.v : Self-checking testbench for aes128_core
// ---------------------------------------------------------------
// 1. Runs the FIPS-197 Appendix B example and prints the state after
//    every round (compare with FIPS-197 Appendix B / results file).
// 2. Runs all vectors in test_vectors.mem (2 FIPS + 100 random) and
//    compares each ciphertext with the expected value.
// 3. Measures latency (clock cycles from start to done).
// 4. Writes a summary to sim_results.txt in the simulation run folder.
//
// Clock: 100 MHz (10 ns period).
// test_vectors.mem must be added to the Vivado project as a simulation source.
// ---------------------------------------------------------------
`timescale 1ns/1ps
module tb_aes128_core;

    localparam NUM_VECTORS = 102;     // = value printed by python/gen_vectors.py
    localparam CLK_PERIOD  = 10;

    reg          clk = 1'b0;
    reg          rst = 1'b1;
    reg          start = 1'b0;
    reg  [127:0] plaintext = 128'd0;
    reg  [127:0] key       = 128'd0;
    wire [127:0] ciphertext;
    wire         busy, done;

    aes128_core dut (
        .clk(clk), .rst(rst), .start(start),
        .plaintext(plaintext), .key(key),
        .ciphertext(ciphertext), .busy(busy), .done(done)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    reg [127:0] vec_mem [0:3*NUM_VECTORS-1];
    reg [127:0] expected;
    integer i, pass_count, fail_count, cycles, fd;
    integer trace_on;

    // ---- Round-by-round trace (printed only for the first vector) ----
    // Sampled on the falling edge, half a cycle after the registers update.
    // After the load edge round=1 -> prints round 0; after round r -> prints r;
    // after round 10 the counter returns to 0 and 'done' is high -> prints 10.
    always @(negedge clk) begin
        if (trace_on && (dut.busy || dut.done)) begin
            $display("   round %2d | round key = %032h | state = %032h",
                     (dut.round == 0) ? 10 : dut.round - 1, dut.round_key, dut.state);
        end
    end

    // ---- Encrypt one block and return latency in 'cycles' ----
    task run_block;
        input [127:0] k;
        input [127:0] p;
        begin
            @(negedge clk);
            key = k; plaintext = p; start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            cycles = 1;
            while (!done) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
        end
    endtask

    initial begin
        $readmemh("test_vectors.mem", vec_mem);
        fd = $fopen("sim_results.txt", "w");
        pass_count = 0; fail_count = 0; trace_on = 0;

        repeat (3) @(negedge clk);
        rst = 1'b0;

        // ---------- Part 1: FIPS-197 Appendix B with round trace ----------
        $display("");
        $display("==== Part 1: FIPS-197 Appendix B example (round-by-round) ====");
        $display("   key       = %032h", vec_mem[0]);
        $display("   plaintext = %032h", vec_mem[1]);
        trace_on = 1;
        run_block(vec_mem[0], vec_mem[1]);
        @(posedge clk);          // let the trace print the final round first
        trace_on = 0;
        $display("   ciphertext= %032h  (expected %032h)  %s",
                 ciphertext, vec_mem[2], (ciphertext == vec_mem[2]) ? "PASS" : "FAIL");
        $display("   latency   = %0d clock cycles (start -> done)", cycles);

        // ---------- Part 2: all vectors ----------
        $display("");
        $display("==== Part 2: %0d test vectors ====", NUM_VECTORS);
        for (i = 0; i < NUM_VECTORS; i = i + 1) begin
            expected = vec_mem[3*i+2];
            run_block(vec_mem[3*i], vec_mem[3*i+1]);
            if (ciphertext === expected) begin
                pass_count = pass_count + 1;
                if (i < 5)
                    $display("   [%3d] PASS  ct = %032h  (%0d cycles)", i, ciphertext, cycles);
            end else begin
                fail_count = fail_count + 1;
                $display("   [%3d] FAIL  got %032h expected %032h", i, ciphertext, expected);
            end
            $fdisplay(fd, "%0d,%032h,%032h,%032h,%032h,%0d,%s", i, vec_mem[3*i],
                      vec_mem[3*i+1], ciphertext, expected, cycles,
                      (ciphertext === expected) ? "PASS" : "FAIL");
        end
        if (NUM_VECTORS > 5) $display("   ... (remaining results in sim_results.txt)");

        // ---------- Summary ----------
        $display("");
        $display("==== SUMMARY ====");
        $display("   Vectors tested : %0d", NUM_VECTORS);
        $display("   PASS           : %0d", pass_count);
        $display("   FAIL           : %0d", fail_count);
        $display("   Latency        : %0d cycles/block", cycles);
        $display("   Throughput     : 128 bits / %0d cycles = %0d.%02d bits/cycle",
                 cycles, 128 / cycles, (12800 / cycles) % 100);
        if (fail_count == 0) $display("   RESULT         : ALL TESTS PASSED");
        else                 $display("   RESULT         : *** FAILURES FOUND ***");
        $fclose(fd);
        #20 $finish;
    end
endmodule
