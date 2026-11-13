// aes_key_expand.v : one step of AES-128 key expansion (on-the-fly)
// Given round key i (words w0..w3) and Rcon for round i+1, produce round key i+1.
//   temp = SubWord(RotWord(w3)) ^ {rcon, 24'h0}
//   n0 = w0 ^ temp;  n1 = w1 ^ n0;  n2 = w2 ^ n1;  n3 = w3 ^ n2
`timescale 1ns/1ps
module aes_key_expand (
    input  wire [127:0] key_in,
    input  wire [7:0]   rcon,
    output wire [127:0] key_out
);
    wire [31:0] w0 = key_in[127:96];
    wire [31:0] w1 = key_in[95:64];
    wire [31:0] w2 = key_in[63:32];
    wire [31:0] w3 = key_in[31:0];

    wire [31:0] rot = {w3[23:0], w3[31:24]};   // RotWord: [a b c d] -> [b c d a]
    wire [31:0] sub;                           // SubWord: S-box on each byte

    aes_sbox u_s0 (.in_byte(rot[31:24]), .out_byte(sub[31:24]));
    aes_sbox u_s1 (.in_byte(rot[23:16]), .out_byte(sub[23:16]));
    aes_sbox u_s2 (.in_byte(rot[15:8]),  .out_byte(sub[15:8]));
    aes_sbox u_s3 (.in_byte(rot[7:0]),   .out_byte(sub[7:0]));

    wire [31:0] temp = sub ^ {rcon, 24'h000000};
    wire [31:0] n0 = w0 ^ temp;
    wire [31:0] n1 = w1 ^ n0;
    wire [31:0] n2 = w2 ^ n1;
    wire [31:0] n3 = w3 ^ n2;

    assign key_out = {n0, n1, n2, n3};
endmodule
