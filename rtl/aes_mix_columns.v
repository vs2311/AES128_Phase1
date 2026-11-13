// aes_mix_columns.v : MixColumns transformation
// Each 32-bit column [a0 a1 a2 a3] is multiplied in GF(2^8) by
//   | 02 03 01 01 |
//   | 01 02 03 01 |
//   | 01 01 02 03 |
//   | 03 01 01 02 |
// Multiply-by-2 is "xtime": shift left, XOR 0x1B if the MSB was 1.
// Multiply-by-3 = xtime(a) ^ a.
`timescale 1ns/1ps
module aes_mix_columns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    function [7:0] xtime;
        input [7:0] a;
        begin
            xtime = {a[6:0], 1'b0} ^ (a[7] ? 8'h1b : 8'h00);
        end
    endfunction

    function [31:0] mix_col;
        input [31:0] col;            // col[31:24] = row 0 ... col[7:0] = row 3
        reg [7:0] a0, a1, a2, a3;
        begin
            a0 = col[31:24]; a1 = col[23:16]; a2 = col[15:8]; a3 = col[7:0];
            mix_col[31:24] = xtime(a0) ^ (xtime(a1) ^ a1) ^ a2 ^ a3;
            mix_col[23:16] = a0 ^ xtime(a1) ^ (xtime(a2) ^ a2) ^ a3;
            mix_col[15:8]  = a0 ^ a1 ^ xtime(a2) ^ (xtime(a3) ^ a3);
            mix_col[7:0]   = (xtime(a0) ^ a0) ^ a1 ^ a2 ^ xtime(a3);
        end
    endfunction

    assign state_out[127:96] = mix_col(state_in[127:96]);  // column 0
    assign state_out[95:64]  = mix_col(state_in[95:64]);   // column 1
    assign state_out[63:32]  = mix_col(state_in[63:32]);   // column 2
    assign state_out[31:0]   = mix_col(state_in[31:0]);    // column 3
endmodule
