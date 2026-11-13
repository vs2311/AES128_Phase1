// aes128_core.v : Iterative AES-128 encryption core (top module)
// ---------------------------------------------------------------
// Architecture : one AES round per clock cycle, round keys generated on the fly
// Latency      : 11 clock cycles from 'start' to 'done'
//                (1 cycle initial AddRoundKey + 10 rounds)
// Interface    : pulse 'start' for one cycle with plaintext/key valid.
//                'busy' is high while encrypting; 'done' pulses for one cycle
//                when 'ciphertext' is valid (ciphertext holds until next start).
// Reset        : synchronous, active-high 'rst'.
// ---------------------------------------------------------------
`timescale 1ns/1ps
module aes128_core (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    output reg  [127:0] ciphertext,
    output reg          busy,
    output reg          done
);
    reg  [127:0] state;      // AES state register
    reg  [127:0] round_key;  // current round key register
    reg  [3:0]   round;      // round counter 1..10

    // ---------------- Rcon lookup (round constant) ----------------
    reg [7:0] rcon;
    always @(*) begin
        case (round)
            4'd1:  rcon = 8'h01;
            4'd2:  rcon = 8'h02;
            4'd3:  rcon = 8'h04;
            4'd4:  rcon = 8'h08;
            4'd5:  rcon = 8'h10;
            4'd6:  rcon = 8'h20;
            4'd7:  rcon = 8'h40;
            4'd8:  rcon = 8'h80;
            4'd9:  rcon = 8'h1b;
            4'd10: rcon = 8'h36;
            default: rcon = 8'h00;
        endcase
    end

    // ---------------- Round datapath (combinational) ----------------
    wire [127:0] sb_out, sr_out, mc_out, next_key;

    aes_sub_bytes   u_sb (.state_in(state),  .state_out(sb_out));
    aes_shift_rows  u_sr (.state_in(sb_out), .state_out(sr_out));
    aes_mix_columns u_mc (.state_in(sr_out), .state_out(mc_out));
    aes_key_expand  u_ke (.key_in(round_key), .rcon(rcon), .key_out(next_key));

    // Final round (round 10) skips MixColumns
    wire [127:0] round_out = (round == 4'd10) ? (sr_out ^ next_key)
                                               : (mc_out ^ next_key);

    // ---------------- Control FSM + registers ----------------
    always @(posedge clk) begin
        if (rst) begin
            state      <= 128'd0;
            round_key  <= 128'd0;
            round      <= 4'd0;
            ciphertext <= 128'd0;
            busy       <= 1'b0;
            done       <= 1'b0;
        end else begin
            done <= 1'b0;                         // default: done is a 1-cycle pulse
            if (start && !busy) begin
                state     <= plaintext ^ key;     // initial AddRoundKey (round 0)
                round_key <= key;
                round     <= 4'd1;
                busy      <= 1'b1;
            end else if (busy) begin
                state     <= round_out;
                round_key <= next_key;
                if (round == 4'd10) begin
                    ciphertext <= round_out;
                    busy       <= 1'b0;
                    done       <= 1'b1;
                    round      <= 4'd0;
                end else begin
                    round <= round + 4'd1;
                end
            end
        end
    end
endmodule
