# Arty A7 Board

Current simple design has been tested using real board
- Raw
	- Able to receive packets from host via MAC
	- Able to send packets to host via MAC
	- Able to read/write DRAM via Memory Controller
- Network (SysNet and LibNet)
	- TODO
- MM (SySMM and LibNet)
	- TODO

General
- This design is not optimal. There is a FIFO within Tri-Mode MAC network part,
  and another FIFO after that to convert data bus width. In theory, there should be only one.
- Also, Tri-mode MAC related code is slighted modified from the original reference design
  to let it be able to run on Arty A7 board.
- Majority of the design is using Block Diagram.

## Testing

- Capture Packets: Use `WireShark`
- Generated Packets: Use `tools/pktgen.c` or other tools

# Troubleshooting

## Board File Not Found
Use this [link](https://reference.digilentinc.com/vivado/installing-vivado/start) to download Digilent board files.
Copy the arty series board folders into Xilinx board file folder.
For example:
```
cp -r vivado-boards-master/new/board_files/arty* /opt/Xilinx/Vivado/2018.2/data/boards/board_files/
```
