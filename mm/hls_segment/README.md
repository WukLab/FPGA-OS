# System Memory Management Unit

## Interface

- Relevant Files:
  - `include/fpga/axis_sysmmu_data.h`: system mmu data hls stream Interface
  - `include/fpga/axis_sysmmu_ctrl.h`: system mmu control hls stream interface
  - `include/fpga/sysmmu_type.h`: system mmu opcode
  - `include/fpga/mem_common.h`: return status


- Sample Code (Control path should be access by sysmmu allocator, no access from application directly):
```c++
    void sysmmu_caller()
    {
        axis_sysmmu_ctrl ctrlpath;
        sysmmu_ctrl_if req;
        RET_STATUS stat;

        /*
        * replace capitalized part with your own
        */
        req.opcode = OPCODE;
        req.idx = CHUNK_IDX(addr);
        req.pid = PID;
        req.rw = RW;
        ctrlpath.write(req); // initiate request

        if (stat == SUCCESS) {
            // if your request is accomplished, you are good to go
        } else {
            // out of memory
        }
    }

```

- Data Path
  - datapath should be hook with AXI to AXI stream wrapper, no explicit access through user application
