# Notes

## HLS-based ICAP

It can only read registers from ICAP now.
Readback bitstream seems to have issues.
Writing anything is not implemented.

This method is too hard to implement. That's why I turn to a `MicroBlaze+HWICAP` based solution.

## About floorplan and dynamic-sized PR

Current working design is using `MicroBlaze` and `AXI_HWICAP` combination.
The vivado project is in `floorplan/`. The SDK code is in `mb/sched/core.c`,
which is able to accept bitstream from host to MicroBlaze.

The core part is an MicroBlaze example design, and a manually added `AXI_HWICAP`.
Steps are simple. Everything:

1. Open Vivado GUI, Open Example Project, Choose "Configurable MicroBlaze Design". Make sure you have UART.
2. Once the BD is open, add `AXI_HWICAP` module. Then clock auto-connect. Synthesize, Implement, and Write Bitstream.
3. Inside Vivado, export hardware and open the SDK to program MicroBlaze.
4. In SDK, use the `mb/sched/core.c`.
5. In your host, use `minicom` to open the serial connection with the UART module in FPGA.
   If you are using the original source code, the step in the host are:
    - Open a minicom terminal.
      Press 1, input bitstream file size.
      Press 2, start PR process. DO NOT PRESS ANYTHING AFTER THIS.
    - Then open another minicom terminal.
      Run `cat pr_bitstream.bit > /dev/ttyUSB1`
    - You should see a msg from minicom when it finished.
