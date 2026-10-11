# Basys 3 FPGA: SoC & Async FIFO Data Router

This project implements a complete System-on-Chip (SoC) architecture on a Digilent Basys 3 FPGA using Verilog. The primary focus of this design is managing Clock Domain Crossing (CDC) and routing data packets reliably across different clock frequencies to multiple peripheral interfaces.

## 🛠️ Architecture Overview

The system bridges a high-speed data generator with a slower core routing network, outputting real-time data to four different physical interfaces.

1. **Traffic Generator (100MHz):** Simulates high-speed incoming data packets.
2. **Asynchronous FIFO:** Safely transfers data from the 100MHz RX domain to the 25MHz SYS domain, mitigating metastability using synchronized Gray counters.
3. **Packet Parser:** Analyzes 64-bit packets, checks for errors (`HEADER_ERR`, `DATA_ERR`), and strips the 32-bit payload and 2-bit Destination ID.
4. **Packet Router:** Uses a full `VALID`/`READY` handshake mechanism to route the payload to the designated peripheral.
5. **Clocking Wizard (PLL):** Down-converts the 100MHz onboard oscillator (pin W5) to a stable 25MHz system clock.

## 📦 Packet Structure (64-bit)
* `[63:62]` **Header**: `2'b10` (Validates packet start).
* `[61:60]` **Destination ID**: Routes data to (00: 7-Segment, 01: VGA, 10: UART, 11: LEDs).
* `[59:32]` **Reserved**: Set to zero for 64-bit alignment and future scalability (e.g., timestamps, priority flags).
* `[31:0]` **Data**: 32-bit payload to be displayed/transmitted.

## 🖥️ Peripherals (25MHz Domain)
* **VGA Driver:** Handles sync signals and pixel generation for external monitors.
* **7-Segment Driver:** Implements time-multiplexing to display 32-bit values across 4 physical digits.
* **LED Driver:** Smart multiplexing to display segments of the data payload.
* **UART TX Driver:** A custom Finite State Machine (FSM) transmitting data at 115200 baud rate. *Note: Tested by connecting the Basys 3 directly to an Android smartphone via a USB OTG adapter, viewing data in a serial terminal.*

## 📁 Repository Structure
* `*.v` (root): Verilog RTL modules. The top level is `top_module.v`.
* `Basys3_Master.xdc` (root): Physical constraint file mapped for the Basys 3 board.
* `/verification`: SystemVerilog testbench for the asynchronous FIFO, with its own README.

## 🚀 Environment
* **Hardware:** Digilent Basys 3 (Artix-7 FPGA)
* **Software:** Xilinx Vivado
* **Language:** Verilog

## ✅ Verification
The asynchronous FIFO is verified with a class-based, layered SystemVerilog testbench (generator, driver, monitor, scoreboard, environment), located in [`/verification`](verification/).
* Independent write and read streams, each at full speed in its own clock domain, with non-aligned clocks.
* Checks data integrity, FIFO ordering, overflow/underflow, and FULL/EMPTY flag correctness.
* The testbench found a read-latency mismatch between the RTL and the Block Memory IP configuration, which was then fixed.

See [`verification/README.md`](verification/README.md) for details.
