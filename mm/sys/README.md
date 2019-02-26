# MM Top-level System

The top-level design is a block diagram that connects:
- AXI Wrapper
- MMU Agent (Segment or Paging)
- Fault Handling Agent (Segment or Paging)

The BD has signals for datapath, which is the AXI. It also has control
path signals for 1) allocation, 2) misc management.

Scripts created by:
```
write_project_tcl -force -target_proj_dir ./generated_vivado_project ./run_vivado.tcl
```
