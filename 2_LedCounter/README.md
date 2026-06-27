# 2_LedCounter

Display a binary counter on the six onboard LEDs of the Tang Nano 9K.

A 32-bit register increments every clock cycle. Six upper bits of the counter are connected to the LED outputs.

The LED assignment is:

```verilog
assign led = ~counter[26:21];
