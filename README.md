# AES-128 Encryption Core in Verilog — Phase 1 (Simulation in Vivado)

B.Tech project, team of two. Phase 1 (this semester) = design understanding +
behavioural simulation + synthesis reports. Phase 2 (Dec–Feb) = FPGA board.

## Folder contents

| Folder / file | What it is |
|---|---|
| `rtl/aes128_core.v` | **Top module.** Iterative AES-128 encryptor, 1 round per clock, 11 cycles per block |
| `rtl/aes_sub_bytes.v`, `aes_sbox.v` | SubBytes (16 S-boxes) |
| `rtl/aes_shift_rows.v` | ShiftRows (wiring only) |
| `rtl/aes_mix_columns.v` | MixColumns (GF(2^8) xtime logic) |
| `rtl/aes_key_expand.v` | On-the-fly round-key generation |
| `tb/tb_aes_units.v` | Unit tests for each block — **run this first** |
| `tb/tb_aes128_core.v` | Main self-checking testbench (round trace + 102 vectors + latency) |
| `tb/test_vectors.mem` | 102 vectors: 2 official FIPS-197 + 100 random (key, plaintext, ciphertext) |
| `python/aes_ref.py` | Pure-Python golden model, same structure as the RTL |
| `python/gen_vectors.py` | Regenerates `test_vectors.mem` |
| `python/avalanche.py` | Avalanche-effect plots for the report |
| `vivado/create_project.tcl` | One command: creates the project and runs the simulation |
| `vivado/synth_report.tcl` | Synthesis only → LUT / FF / timing reports |
| `results/` | Reference results: expected console output, round trace, avalanche plots |

## Block diagram (aes128_core)

```
 plaintext ──► XOR ◄── key            (round 0, on 'start')
               │
               ▼
        ┌──── state reg ◄──────────────────────────────┐
        │                                              │
        ▼                                              │
   SubBytes ─► ShiftRows ─► MixColumns ─┬─► XOR ───────┤
                    │      (skip in round 10)  ▲        │
                    └──────────────────────────┘        │
   round_key reg ─► KeyExpand(Rcon[round]) ────► next_key
   round counter 1..10 (FSM) ─► done pulse, ciphertext reg
```

## Run the simulation (GUI, no Tcl)

1. Vivado → *Create Project* → RTL Project → part `xc7a35tcpg236-1` (any part is fine for simulation).
2. *Add Sources → Design sources*: all files in `rtl/`.
3. *Add Sources → Simulation sources*: both files in `tb/` **and** `tb/test_vectors.mem`.
4. In *Sources → Simulation Sources*, right-click `tb_aes_units` → *Set as Top* → *Run Simulation → Run Behavioral Simulation*. Expect 6 PASS lines.
5. Set `tb_aes128_core` as top and run again. In the Tcl Console you should see the round-by-round trace and `RESULT : ALL TESTS PASSED`. Compare with `results/expected_vivado_console.txt`.
6. In the waveform window: add `dut/round`, `dut/state`, `dut/round_key`; set radix to Hexadecimal; zoom to one 11-cycle encryption and take a screenshot for the report.

**Tcl shortcut:** in the Vivado Tcl Console, `cd` to the `vivado/` folder, then `source create_project.tcl`.

## Synthesis numbers (no board needed)

In the Tcl Console (from the `vivado/` folder): `source synth_report.tcl`.
Read `vivado/reports/utilization_synth.txt` (Slice LUTs, Registers) and
`timing_synth.txt` (WNS > 0 means it meets 100 MHz). Max frequency ≈ 1000 / (10 − WNS) MHz.

## Python scripts (optional, Python 3)

```
cd python
python aes_ref.py                 # round-by-round trace of the FIPS example
python gen_vectors.py 100         # regenerate vectors (update NUM_VECTORS in the testbench if you change the count)
python avalanche.py               # needs matplotlib
```

## Common problems

| Symptom | Fix |
|---|---|
| `test_vectors.mem` not found / all FAIL with `x` values | Add the .mem file as a **simulation source** (step 3) |
| Simulation stops at 1000 ns | Settings → Simulation → xsim.simulate.runtime = `all` (the Tcl script sets this) |
| Waveform shows only testbench signals | Scope window → expand `dut` → drag signals into the wave window, then *Restart* + *Run All* |
| Synthesis error "too many I/Os" | Use `synth_report.tcl` (out-of-context mode); the board wrapper comes in Phase 2 |

## Notes

- The algorithm and the RTL's byte ordering were checked against FIPS-197 and an independent AES library (500 random blocks) using a cycle-level Python mirror of the RTL. The students' own Vivado run is the actual RTL simulation result for the report.
- Reference: NIST FIPS-197, *Advanced Encryption Standard (AES)*, 2001 (updated 2023).
