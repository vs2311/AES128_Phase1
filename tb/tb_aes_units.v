// tb_aes_units.v : Unit tests for the individual AES building blocks.
// Run this FIRST (Day 2-3) to learn simulation on small modules.
// Known answers are from FIPS-197.
`timescale 1ns/1ps
module tb_aes_units;

    integer errors = 0;

    // ---------- S-box ----------
    reg  [7:0] sb_in;
    wire [7:0] sb_out;
    aes_sbox u_sbox (.in_byte(sb_in), .out_byte(sb_out));

    // ---------- ShiftRows, MixColumns ----------
    reg  [127:0] st_in;
    wire [127:0] sr_out, mc_out;
    aes_shift_rows  u_sr (.state_in(st_in), .state_out(sr_out));
    aes_mix_columns u_mc (.state_in(st_in), .state_out(mc_out));

    // ---------- Key expansion ----------
    reg  [127:0] k_in;
    reg  [7:0]   rcon;
    wire [127:0] k_out;
    aes_key_expand u_ke (.key_in(k_in), .rcon(rcon), .key_out(k_out));

    task check8;  input [7:0] got, exp; input [8*24-1:0] name;
        begin
            if (got === exp) $display("PASS  %0s : %02h", name, got);
            else begin $display("FAIL  %0s : got %02h expected %02h", name, got, exp); errors = errors + 1; end
        end
    endtask

    task check128; input [127:0] got, exp; input [8*24-1:0] name;
        begin
            if (got === exp) $display("PASS  %0s : %032h", name, got);
            else begin $display("FAIL  %0s : got %032h expected %032h", name, got, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        $display("==== AES unit tests ====");
        // S-box (FIPS-197 Fig. 7)
        sb_in = 8'h00; #10 check8(sb_out, 8'h63, "SBOX(00)");
        sb_in = 8'h53; #10 check8(sb_out, 8'hed, "SBOX(53)");
        sb_in = 8'hff; #10 check8(sb_out, 8'h16, "SBOX(ff)");

        // ShiftRows: bytes 00..0f -> rows rotated
        st_in = 128'h000102030405060708090a0b0c0d0e0f;
        #10 check128(sr_out, 128'h00050a0f04090e03080d02070c01060b, "ShiftRows");

        // MixColumns: FIPS-197 Appendix B, round 1 (after ShiftRows -> after MixColumns)
        st_in = 128'hd4bf5d30e0b452aeb84111f11e2798e5;
        #10 check128(mc_out, 128'h046681e5e0cb199a48f8d37a2806264c, "MixColumns");

        // Key expansion: FIPS-197 Appendix A.1, round key 1
        k_in = 128'h2b7e151628aed2a6abf7158809cf4f3c; rcon = 8'h01;
        #10 check128(k_out, 128'ha0fafe1788542cb123a339392a6c7605, "KeyExpand round 1");

        $display("==== %0d error(s) ====", errors);
        #10 $finish;
    end
endmodule
