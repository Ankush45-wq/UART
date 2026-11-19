# UART
# UART Communication System – TX and RX

## 1. Project Overview

This project implements a UART (Universal Asynchronous Receiver/Transmitter) communication system using Verilog/SystemVerilog RTL.

The design consists of two independent modules:

- **UART Transmitter (TX):** Converts parallel data into serial data for transmission.
- **UART Receiver (RX):** Receives serial data and reconstructs the original parallel data.

The project focuses on understanding UART communication, baud rate generation, finite state machines (FSM), serial data transmission, and reception.

## 2. Design Specifications

| Parameter | Configuration |
|---|---|
| Clock Frequency | 50 MHz |
| Baud Rate | 9600 |
| Data Width | 8 bits |
| Data Transmission | LSB First |
| Start Bit | 1 bit |
| Stop Bit | 1 bit |
| Parity | Optional in RX design |

## 3. UART Transmitter (TX)

The transmitter converts 8-bit parallel input data into serial output.

### TX Modules

- **baud_gen:** Generates baud-rate timing pulses using the system clock.
- **shift_reg:** Stores and shifts the input data, transmitting the least significant bit first.
- **bit_counter:** Tracks the number of transmitted data bits.
- **uart_tx_fsm:** Controls the transmission sequence through IDLE, START, DATA, and STOP states.
- **top:** Integrates the transmitter modules.

### TX Operation

1. Waits for a transmission request.
2. Loads the input data into the shift register.
3. Generates the start bit.
4. Transmits 8 data bits, LSB first.
5. Generates the stop bit.
6. Returns to the idle state.

## 4. UART Receiver (RX)

The receiver captures incoming serial data and reconstructs the original 8-bit parallel data.

### RX Modules

- **synchronizer:** Synchronizes the incoming serial signal with the receiver clock.
- **start_bit_detector:** Detects the beginning of an incoming UART frame.
- **baud_gen:** Generates baud-rate and half-bit timing signals.
- **uart_fsm:** Controls the reception process using IDLE, START, DATA, PARITY, STOP, and DONE states.
- **bit_counter:** Tracks the received data bits.
- **shift_reg:** Reconstructs the received parallel data.
- **parity_checker:** Performs XOR-based parity checking when parity is enabled.

### RX Operation

1. Synchronizes the incoming serial data.
2. Detects the start bit.
3. Uses baud-rate timing to sample incoming data.
4. Receives 8 data bits and reconstructs the parallel output.
5. Supports an optional parity-checking path.
6. Processes the stop bit and completes reception.

## 5. Tools and Technologies

- Verilog / SystemVerilog
- RTL Design
- Finite State Machines (FSM)
- Digital Design
- UART Serial Communication

## 6. Verification Plan

The planned verification activities include:

- UART TX data transmission testing.
- UART RX data reception testing.
- Baud-rate timing verification.
- LSB-first data transmission and reception.
- Start and stop bit checking.
- Optional parity testing in RX.
- Different input data pattern testing.
- UART TX-to-RX loopback testing.

## 7. Project Structure

```text
UART-Communication-System/
│
├── rtl/
│   ├── uart_tx/
│   │   ├── baud_gen.sv
│   │   ├── shift_reg.sv
│   │   ├── bit_counter.sv
│   │   ├── uart_tx_fsm.sv
│   │   └── uart_tx_top.sv
│   │
│   └── uart_rx/
│       ├── synchronizer.sv
│       ├── start_bit_detector.sv
│       ├── baud_gen.sv
│       ├── uart_fsm.sv
│       ├── bit_counter.sv
│       ├── shift_reg.sv
│       └── parity_checker.sv
│
├── tb/
│   ├── tb_uart_tx.sv
│   ├── tb_uart_rx.sv
│   └── tb_uart_loopback.sv
│
├── docs/
│
└── README.md
```

## 8. Current Project Status

**Status: RTL Development and Debugging in Progress**

The UART TX and RX RTL modules have been developed. Compilation, functional debugging, and self-checking testbench development are the next steps.

## 9. Learning Objectives

- Understand UART serial communication.
- Design baud-rate generators.
- Implement FSM-based transmitter and receiver architectures.
- Understand serial-to-parallel and parallel-to-serial conversion.
- Develop RTL debugging and verification skills.

---

**Author:** Ankush Pandey

**Project:** UART Communication System – TX and RX
