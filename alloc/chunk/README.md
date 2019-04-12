# Chunk Allocator

## Interface

- Relevant Files:
  - `include/fpga/axis_sysmmu.h`: sysmmu allocation hls stream interface and opcode


- Sample Code:
```c++
    void chunk_allocator_caller()
    {
        hls::stream<sysmmu_alloc_if> alloc;
        hls::stream<sysmmu_alloc_ret_if> alloc_ret;
        sysmmu_alloc_if req;
        sysmmu_alloc_ret_if ret;

        /*
        * replace capitalized part with your own
        */
        req.opcode = OPCODE;
        req.idx = CHUNK_IDX(addr);
        req.pid = PID;
        req.rw = RW;
        alloc.write(req); // send request to sysmmu

        /* read return */
        while (alloc_ret.empty());
        ret = alloc_ret.read();

        if (ret == 0) {
            // request success
        } else {
            // out of memory or some internal error
        }
    }

```
