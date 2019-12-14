# Buddy Allocator
Last Updated: Dec 2, 2019

## Interface

- Relevant Files:
  - `include/fpga/axis_buddy.h`: buddy hls stream interface
  - `include/fpga/buddy_type.h`: buddy allocator opcode
  - `include/fpga/mem_common.h`: return status


- Sample Code:
```c++
    void buddy_caller()
    {
        axis_buddy_alloc alloc;
        axis_buddy_alloc_ret alloc_ret;
        buddy_alloc_if req;
        RET_STATUS stat;

        /*
        * replace capitalized part with your own
        */
        req.opcode = OPCODE;
        req.order = ORDER;
        req.addr = ADDR; // only necessary for FREE request
        alloc.write(req); // send request to buddy

        if (stat == SUCCESS) {
            // if your request is alloc, you can read from alloc_ret
            // if your request is free, you are good to go
        } else {
            // out of memory
        }
    }

```

## Dev Note

- To make the start address of buddy allocator configurable, we set the macro `BUDDY_START` to 0, and set the `bram_addr` (the real start address) variable to what we want through the `init()` function. In this way we fool the allocator that it was managing the physical memory from 0 to 1GB, while it still writes the metadata to `bram_addr`. As a result, we need to add `bram_addr` as an offset to the returned address during ALLOC and subtract `bram_addr` from the request address during FREE.
