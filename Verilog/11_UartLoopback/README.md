# 11_UartLoopback

Receive a UART byte and transmit the same byte back.

PC terminal -> USB-UART TX -> FPGA uart_rx
FPGA uart_tx -> USB-UART RX -> PC terminal
