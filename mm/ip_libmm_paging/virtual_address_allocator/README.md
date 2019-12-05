# Buddy Allocator (Heap Allocator)

This allocator is for managing the heap in the virtual address space, different from the buddy allocator at `alloc/buddy/` which is used for allocating physical address. The difference is this allocator can manage 4GB (`BUDDY_MAX_SHIFT` is 32) while that one can manage 1GB (`BUDDY_MAX_SHIFT` is 30).

This may seems wired since usually we use linklist to manage the heap. But that is hard to implement on hardware so we use this to workaround.

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
