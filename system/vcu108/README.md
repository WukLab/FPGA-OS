# VCU108

The board only use one type of memory controller, but it has two MACs
- AXI Ethernet Subsystem
- QSPF

Our system, essentially is `LegoFPGA.bd`. We put everything within
the BD design, which is easy to generate and easy to build.

The `LegoFPGA.bd` essentially has three major interfaces
- AXI-Stream from MAC
- AXI-Stream to MAC
- DDR to DRAM

Keep in mind.


## Issues

Having AXI Ethernet Subsystem within the example design, the whole thing can NOT be
exported a Block Diagram IP, which is annoying.

One possible way to do it is extract the SM/clock as a standlone RTL IP, and
then merge it with a MAC IP in a BD design. Doable. Later.


## Cheatsheet

Convert generated bitstream into flash-format bitstream:
```
vivado -mode tcl -source convert_bit_mcs.tcl -tclargs ./generated_vivado_project/generated_vivado_project.runs/impl_1/XXX.bit ./XXX.mcs
```

```
vivado -mode tcl -source program_bpi.tcl -tclargs ./top_pcie_RDM.mcs
```


## About C2H Bypass

The xdma has a feature called C2H bypass, which let FPGA logic to feed the descriptor
directly without involving host CPU. This means FPGA logic can controll DMA to host
DRAM. In order to have a convenient testing setup, we added this support.

Some notes:
- `dsc_bypass_c2h_dsc_byp_src_addr` is not used, set to 0.
- `dsc_bypass_c2h_dsc_byp_ctl` should be 0, check the datasheet
- `dsc_bypass_c2h_dsc_byp_dst_addr` is the host physical DRAM address
	- Ideally, it should increment.
	- For now, write to fixed location which is reserved by memmap.
- `dsc_bypass_c2h_dsc_byp_len`
- `dsc_bypass_c2h_dsc_byp_load`: assert to 1 when ready is asserted.
	- Also tried set it to constant 1, works. But let's do current way.

Related code:
```
	reg dsc_bypass_c2h_dsc_byp_load;
	wire dsc_bypass_c2h_dsc_byp_ready;

	always @ (posedge user_clk_250) begin
		if (!user_resetn_250) begin
			dsc_bypass_c2h_dsc_byp_load <= 1'b0;
		end else begin
			if (dsc_bypass_c2h_dsc_byp_ready) begin
				dsc_bypass_c2h_dsc_byp_load <= 1'b1;
			end else begin
				dsc_bypass_c2h_dsc_byp_load <= 1'b0;
			end
		end
	end

	pcie_c2h_bypass u_pcie (
		...
		...

		// descriptor bypass
		// dst_addr should have been reserved via memmap
		.dsc_bypass_c2h_dsc_byp_dst_addr	(64'h100000000),
		.dsc_bypass_c2h_dsc_byp_src_addr	(64'h0),
		.dsc_bypass_c2h_dsc_byp_len		(28'h1000),
		.dsc_bypass_c2h_dsc_byp_ctl		(16'h0),
		.dsc_bypass_c2h_dsc_byp_ready		(dsc_bypass_c2h_dsc_byp_ready),
		.dsc_bypass_c2h_dsc_byp_load		(dsc_bypass_c2h_dsc_byp_load),
		
		...
		...
	);
```
