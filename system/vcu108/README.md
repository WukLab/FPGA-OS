# VCU108

## TODO

- For C2H: having circular buffers. We need to get the length of each DMA transfer.
  The descriptor itself now is using a very large length. Actual DMA length can be
  smaller than the number we wrote on verilog file, once a tlast is encounted.

- Combine RDM/KVS testing

- AddrMap extension

## Checklist

- Top file
- BD included in the top
- Synthesis and Implementation Strategies

## About the codebase

Those `rtl/top_*.v` files are top-level module that being synthesised and implemented.
Those `top_pcie_c2h_*.v` files are different in that they have C2H bypass enabled XDMA.

For RDM or KVS BDs, there are two versions of each: raw and all. Those raw ones are the ones
that only include RDM/KVS itself. Those all ones are the ones that come with LibNet and SysMem.
Make sure raw ones work before moving on to those all ones.

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
