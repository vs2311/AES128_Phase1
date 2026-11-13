// aes_sub_bytes.v : SubBytes transformation on the full 128-bit state
// 16 parallel S-boxes, one per byte.
// Byte convention (same as FIPS-197): byte k = state[127-8k -: 8]
//   byte 0 is the most significant byte; state is filled column by column.
`timescale 1ns/1ps
module aes_sub_bytes (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : g_sbox
            aes_sbox u_sbox (
                .in_byte (state_in [127-8*k -: 8]),
                .out_byte(state_out[127-8*k -: 8])
            );
        end
    endgenerate
endmodule
