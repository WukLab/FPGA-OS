# FPGA

Copyright (c) 2019, Wuklab, UCSD.

Last Updated: Sep 12, 2019

Codebase Organization Principles:
- Make each subfolder be an IP on its own. This means it should have its own
  scripts, rtl or hls code, and testbench.
- Hierarchy IPs will have dependency. We need to express the order explicitly
  in corresponding building scripts.
- Final large project should be expressed in a diagram or static RTL code
  that ultilizing small IP cores.
- Overall, this project will consist many small IPs, and they will be used
  internally to build large ones. Our goal is to be able to reuse IPs as much as
  possible, and be able to construct new IPs easily.

Codebase Directories:
- Host Side:
	- `host/`: Host side network stack
- FPGA Side:
	- `alloc/`: memory allocator
	- `mm/`: memory management
	- `net/`: network subsystem
	- `system/`: Final big integrated systems
- Both world:
	- `app/`: Application can have both FPGA and Host code.
	- `include/`: header files used by both FPGA and host code. E.g., network headers.
		- `include/fpga`: headers used by HLS only
		- `include/uapi`: headers used by both HLS and host code
- Helpers
	- `tools/`: various helpers
	- `scripts/`: template script files
- Generated
	- `generated_ip/`: all generated IPs sleep here
	- `generated_hls_project/`: Vivado HLS project
	- `generated_vivado_project/`: Vivado project


Format:
- General
	- Make your readable for others.
	- Remove ending spaces and tabs.
	- Try to use Linux Kernel Coding Style.
- Vivado HLS
	- All Vivado HLS script use `run_hls.tcl` name.
- Verilog
- IP
	- Name IP consistenly. Use subsystem name as prefix.
	  E.g., `mm_axi_wrapper` is the AXI wrapper IP under MM subsystem.

## HOWTO Build

- Type `make help` to see detailed explanation.
- Type `make` at top-level will compile the whole project using default board.
	- Kernel IPs will be compiled first
	- Large system reside in `system/` folder
- Type `make` at each subfolder will compile that folder only.

Workflow: you should compile the project when you first download the source code.
All small, medium IPs, and big projects will be ready to use. After this, you
can focus on the IPs you are building. Changes will be reflected automatically within Vivado.

Also, pay attention to which board you are targeting.

## HOWTO use the Vivado script

The goal of using scripts are two-fold
- Make the building process easier
- Use Git to track source files only.
  Because by default Vivado will create bunch files, and all of them should not
  be tracked by Git. In this project, all Vivado project-mode related files
  are placed under `generated_vivado_project/` folder, at the same folder
  where the corresponding script and source code are.

Those Vivado project-mode scripts are generated by Vivado itself. And those
scripts can be used to rebuild the whole project AS IS.

Those are my unformal steps to create and hack those scripts:

Run:
- Run the script:
	- `vivado -mode tcl -source run_vivado.tcl`
		- A new `generated_vivado_project/` will be created at the current folder
		- A new IP will be packaged and exported into `generated_ip/` folder.
	- If you don't want to type it everytime, use a template Makefile.

Creation:
- Create the top-level script:
	- Use Vivado GUI to create a new project, add existing sources/tb/xdc, set part.
	- Use `write_project_tcl` to generate the script. You SHOULD let the new
	  script know that the going-to-be-rebuilt project should be placed under
	  under folder's `generated_vivado_project`. And you SHOULD name the script
	  to `run_vivado.tcl`.
	- If there is no block diagram (BD) design within project,
	  use: `write_project_tcl -force -no_copy_sources -target_proj_dir ./generated_vivado_project ./run_vivado.tcl`
	- If there are BD designs within project,
	  use: `write_project_tcl -force -target_proj_dir ./generated_vivado_project ./run_vivado.tcl`

Hack:
- Add IP paths to top-level script:
	- This SHOULD be added to every script.
	- All our generated IPs are in `generated_ip/` folder. This makes IP tracking easier.
	  You can add few lines to the script so that Vivado knows where to look for new IPs.
	  Check out `scripts/template_vivado_ip.tcl` for those lines.
- Package IP automatically:
	- This SHOULD be added to every script.
	- We want to let the script to package IP automatially. This can be achieved by adding
	  few lines at the end of the script. Note that you need to specify the destination location,
	  the name of the IP, and so on. All our generated IPs are in `generated_ip/`. For example,
	  `ipx::package_project -root_dir ../../generated_ip/mm_axi_wrapper -vendor wuklab -library user -taxonomy UserIP -import_files -set_current false -force`
- Add more source/xdc/simulation files:
	- First solution, manually change the generated script. Try to find out how those
	  existing files are added, then you can modify the script in a similar way. Tips:
	  search `top.v`, `add_files` etc.
	- Second solution, add files via Vivado GUI, and then use `write_project_tcl` again
	  to generate another script. Then check out the differences.
- Autogenerate BD wrapper
	- This MUST be added if the top-level design is a BD
	- The reason is: if the BD has AXI interface, this AXI will need have predefined
	  frequency property (Does not mean it must run on this, just a property.).
	  By default, it is 100 MHz. If an IP is generated from this BD, and
	  used by a larger IP, this frequency cannot be changed, which is VERY unconvenient.
	  However, if we create a wrapper for the BD, and package the whole project as an IP,
	  then the frequency property can be automatically updated during IP integration.
- Other settings:
	- IMPORTANT!
	- Whatever changes you made via Vivado GUI (e.g., compiling order, xdc order, simulation top file),
	  and if you want to save it for others to use, you need to use `write_project_tcl` to generate a new script
	  and save the corresponding changes. Once you get familiar with Vivado commands, you
	  should be able to do manually by changing script.

Caveats:
- Review the generated script
	- Check if any source files within Vivado auto-generated folder is used in the script.
	  This happens if the write_project_tcl is used not correctly. Having auto-generated
	  files essentially equals a chicken-and-egg issue.

For now, you can find example scripts at the `mm/axi_wrapper/run_vivado.tcl`, and `mm/sys/run_vivado.tcl`.

## HOWTO handle IP version

Vivado only supports one IP version in each version. It's super annonying
if we use generated script. Luckily, there is one way to workaround it.
The following code replace the IP string with a variable. However, be careful
if the updated IP has different ports.

```
set axis_data_fifo [get_ipdefs -filter NAME==axis_data_fifo]
Replace all `xilinx.com:ip:axis_data_fifo:1.1` with `$axis_data_fifo
```

## HOWTO use the Vivado HLS script

The Vivado HLS script is relatively easier than Vivado script.
You can find the template script in `scripts/template_run_hls.tcl`.
You SHOULD customize the parts, files added, frequency, and so.
If you want to automatically build multiple HLS under the same folder, use the `scripts/template_generate_hls.sh`

## References
- [UG1118 Vivado Creating and Packaging Custom IP](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_2/ug1118-vivado-creating-packaging-custom-ip.pdf)
