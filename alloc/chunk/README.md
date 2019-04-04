# Chunk Allocator

## Interface

- Relevant Files:
  - `include/fpga/axis_sysmmu_alloc.h`: sysmmu allocation hls stream interface
  - `include/fpga/sysmmu_type.h`: system mmu opcode
  - `include/fpga/mem_common.h`: return status


- Sample Code:
```c++
    void chunk_allocator_caller()
    {
        axis_sysmmu_alloc alloc;
        axis_sysmmu_alloc_ret alloc_ret;
        sysmmu_alloc_if req;
        sysmmu_alloc_ret_if ret;
        RET_STATUS stat;

        /*
        * replace capitalized part with your own
        */
        req.opcode = OPCODE;
        req.idx = CHUNK_IDX(addr);
        req.pid = PID;
        req.rw = RW;
        ctrlpath.write(req); // send request to sysmmu

        if (stat == SUCCESS) {
            // if your request is alloc, you can read from alloc_ret
            // if your request is free, you are good to go
        } else {
            // out of memory
        }
    }

```
