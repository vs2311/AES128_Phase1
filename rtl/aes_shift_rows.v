// aes_shift_rows.v : ShiftRows transformation (pure wiring, no logic gates)
// State layout (byte index b = 4*column + row; byte b = bits [127-8b : 120-8b]):
//        col0 col1 col2 col3
//   r0:   b0   b4   b8   b12     -> no shift
//   r1:   b1   b5   b9   b13     -> rotate left by 1
//   r2:   b2   b6   b10  b14     -> rotate left by 2
//   r3:   b3   b7   b11  b15     -> rotate left by 3
// new(row r, col c) = old(row r, col (c+r) mod 4)
`timescale 1ns/1ps
module aes_shift_rows (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    // column 0
    assign state_out[127:120]  = state_in[127:120];   // b0  <- b0
    assign state_out[119:112]  = state_in[87:80];   // b1  <- b5
    assign state_out[111:104]  = state_in[47:40];   // b2  <- b10
    assign state_out[103:96]   = state_in[7:0];   // b3  <- b15
    // column 1
    assign state_out[95:88]    = state_in[95:88];   // b4  <- b4
    assign state_out[87:80]    = state_in[55:48];   // b5  <- b9
    assign state_out[79:72]    = state_in[15:8];   // b6  <- b14
    assign state_out[71:64]    = state_in[103:96];   // b7  <- b3
    // column 2
    assign state_out[63:56]    = state_in[63:56];   // b8  <- b8
    assign state_out[55:48]    = state_in[23:16];   // b9  <- b13
    assign state_out[47:40]    = state_in[111:104];   // b10 <- b2
    assign state_out[39:32]    = state_in[71:64];   // b11 <- b7
    // column 3
    assign state_out[31:24]    = state_in[31:24];   // b12 <- b12
    assign state_out[23:16]    = state_in[119:112];   // b13 <- b1
    assign state_out[15:8]     = state_in[79:72];   // b14 <- b6
    assign state_out[7:0]      = state_in[39:32];   // b15 <- b11
endmodule
