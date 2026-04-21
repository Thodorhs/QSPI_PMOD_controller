# QSPI PMOD FPGA Tester (SystemVerilog)

A complete SystemVerilog SPI Memory Controller and automated hardware tester for the **QSPI PMOD board** using a standard 32-bit parallel bus interface (PipeCon). Featuring 1x Winbond W25Q128JV 16MB Flash and 2x APMemory APS6404L 8MB PSRAMs tested on the Nexys A7-100T (xc7a100tcsg324-1) FPGA.

This repository provides a fully synthesizable, out-of-the-box solution to interface with the memory chips, manage SPI timings, and verify hardware integrity over PMOD connectors.

##  Features
* **Automated Testing:** Runs millions of back-to-back `Write -> Read -> Verify` transactions to validate integrity.
* **Fast Read Support:** Implements the `0x0B` Fast Read command with automatic 8-cycle dummy padding.
* **Hardware Flash Translation:** Uses "Magic Addresses" to abstract complex Flash operations (Write Enable, Sector Erase, and Status Polling) into simple 32-bit memory writes.
* **Configurable Clock Divider:** Easily scale the SPI `SCK` frequency to match the signal integrity limits of your FPGA's PMOD pins.
* **Visual Feedback:** Uses FPGA LEDs and 7-segment displays to show test phases, progress, and exact points of failure.

---

## How to Use It

### 1. Hardware Setup
This project is pre-configured and tested on the **Digilent Nexys A7-100T (xc7a100tcsg324-1)**, but the SystemVerilog code can be easily ported to any FPGA. 

Plug the QSPI PMOD board into the top-right PMOD port (`JA`).

### 2. Running the Test
Compile `spi_memory_controller.sv` and `fpga_tester_top.sv` in Vivado and flash your board.
1. Press the **Center Button** to reset the tester.
2. The 7-segment display will show the current test phase:
   * **Phase 1 (`1`):** Stress-testing PSRAM A.
   * **Phase 2 (`2`):** Stress-testing PSRAM B.
   * **Phase 3 (`3`):** Unlocking, erasing, programming, and verifying the Flash memory.
3. The 16 Red LEDs will display the lower 16 bits of the memory address currently being tested.

### 3. Understanding the Results
* 🟢 **Green LED ON:** SUCCESS! All tests across all three chips passed with zero bit-errors.
* 🔴 **Green LED OFF & Red LEDs Frozen:** ERROR! A read transaction returned bad data. The tester immediately halts, and the Red LEDs will freeze to show the lower 16 bits of the current memory address that failled.

---

## Memory Map & "Magic Addresses"

To keep the interface simple, the `spi_memory_controller.sv` exposes a standard 32-bit parallel bus interface (PipeCon). It translates addresses into the correct SPI Chip Select (`CS_n`) and command sequences automatically. 

| Address Range | Target Chip | Internal Action Performed by Controller |
| :--- | :--- | :--- |
| `0x40xx_xxxx` | **Flash (W25Q128)** | Standard Fast Read (`0x0B`) & Page Program (`0x02`) |
| `0x41xx_xxxx` | **Flash (W25Q128)** | **Magic Erase:** Writing here sends WREN (`0x06`) + Sector Erase (`0x20`) |
| `0x42xx_xxxx` | **Flash (W25Q128)** | **Magic Status:** Reading here sends Read Status (`0x05`) to poll the BUSY bit. |
| `0x43xx_xxxx` | **Flash (W25Q128)** | **Magic Unlock:** Writing `0x00` clears Block Protect bits (`0x01`). |
| `0x50xx_xxxx` | **PSRAM A (APS6404L)** | Standard Fast Read (`0x0B`) & Write (`0x02`) |
| `0x60xx_xxxx` | **PSRAM B (APS6404L)** | Standard Fast Read (`0x0B`) & Write (`0x02`) |

## Adjusting the Clock Speed

PMOD connectors are generally not impedance-matched, which can cause signal reflection at high frequencies. If your tester fails immediately (Green LED stays off and the 16 LEDs freeze), your SPI clock might be running too fast for the physical jumper wires.

You can adjust the clock speed by changing `DIVIDER_RATIO` in `spi_memory_controller.sv`. Assuming a 100MHz main FPGA clock:
* `DIVIDER_RATIO = 8` ➔ 12.5 MHz (Highly stable for PMODs)
* `DIVIDER_RATIO = 4` ➔ 25.0 MHz (depends on fpga protection resistors and clock cap)
* `DIVIDER_RATIO = 2` ➔ 50.0 MHz (Requires excellent signal integrity)
