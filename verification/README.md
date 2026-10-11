# Async FIFO Verification

A class-based, layered SystemVerilog testbench for the `async_fifo` module (512 x 64-bit, 100 MHz write / ~27 MHz read).

## Testbench Architecture

```
            environment
 ┌──────────────────────────────────────────────┐
 │  gen_wr ──mbx──┐                              │
 │                ├──► driver ──► fifo_if ──► DUT│
 │  gen_rd ──mbx──┘    (2 loops)     │           │
 │                                   ▼           │
 │            scoreboard ◄──mbx── monitor        │
 │                                (2 loops)      │
 └──────────────────────────────────────────────┘
```

| Component | Role |
|---|---|
| `transaction` | Randomized `wr` / `rd` / 64-bit data, with weighted `dist` constraints |
| `generator` | Two instances: one feeds the write stream, one feeds the read stream |
| `driver` | Two independent loops: write side on `RX_CLK`, read side on `SYS_CLK` |
| `monitor` | Two independent loops, one per clock domain, reporting what actually happened on the pins |
| `scoreboard` | Reference model (queue) + data, ordering and flag checks |
| `environment` | Builds and connects all components; runs `pre_test` / `test` / `post_test` |

## What Is Tested

**Stimulus**
- Write and read sides run **fully independently**, each at its own clock rate. Back-to-back writes at 100 MHz are possible.
- The two clocks have a **non-integer period ratio** (10 ns / 37 ns) plus a phase offset, so the relative edge position keeps changing during the test.
- Each generator runs three phases: **mixed** (70% writes / 50% reads), **fill** (writes only), **drain** (reads only).

**Checks**
| Check | Meaning |
|---|---|
| Data integrity | Every word read equals the oldest unread word written (FIFO order) |
| OVERFLOW | The FIFO must never accept more than 512 words |
| UNDERFLOW | `EMPTY=0` while nothing was written is an error |
| FALSE FULL | `FULL=1` while the FIFO holds fewer than `DEPTH-SLACK` words |
| FALSE EMPTY | `EMPTY=1` while the FIFO holds more than `SLACK` words |
| Completeness | The test fails if FULL or EMPTY was never reached, or if data was left unread |

### Why `SLACK`?
Each flag is computed in its own clock domain, from its own (up-to-date) pointer and the other side's pointer, which arrives through a 2-flop Gray-code synchronizer. So the flags are **late, but always in the safe direction**: `EMPTY` may stay high a few cycles after a write, and `FULL` may stay high a few cycles after a read, but never the opposite. `SLACK` (16 words) allows for this expected synchronization latency while still catching real flag bugs.

## Bugs Found

1. **Read data one word late (design / IP configuration).**
   The scoreboard reported `DATA MISMATCH` on back-to-back reads: each read returned the previous word.
   Root cause: the Block Memory Generator IP had *Primitives Output Register* enabled (read latency 2), while the RTL assumes read latency 1 (the read address is driven with `next_rptr_bin` to pre-fetch the next word).
   Fix: disabled the output register in the IP. All mismatches disappeared.

2. **Stuck `RX_VALID` at end of stimulus (testbench).**
   After the last transaction, `RX_VALID` stayed at its last value, causing dozens of unintended writes.
   Fix: each generator ends its stream with an idle transaction (`wr=0`, `rd=0`).

## Running (Vivado XSim)

1. Add `async_fifo.v`, `bin_to_gray.v` and the `fifo_bram` IP as design sources.
2. Add `TB_HHTP.sv` as a simulation source and set `TB_HHTP` as top.
3. **Important:** in the `fifo_bram` IP, *Port B Options*, keep **Primitives Output Register disabled** (read latency 1).
4. Run Behavioral Simulation, then **Run All**. The scoreboard summary is printed at the end.

Note: behavioral simulation verifies the logic (data, order, flags). Metastability itself cannot be observed in RTL simulation; CDC structure is checked separately with tools such as Vivado `report_cdc`.
