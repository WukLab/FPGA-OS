# List of IPs

| IP  | Location| Description| Configurations|Status|
|:--|:--|:--|:--|:--|
|Buddy|`alloc/buddy`|Buddy allocator|`include/fpga/mem_common.h`, `include/fpga/axis_buddy.h`| C |
|Chunk|`alloc/chunk`|Fix-sized chunk allocator|N/A|S|
|AXI Wrapper|`mm/axi_wrapper`|AXI Wrapper for buffering|N/A|S|
|Segment Checking|`mm/hls_mapping`|Segment table checking|N/A|S|
|HT mapping|`mm/mapping`|mapping table|`include/fpga/axis_mapping.h`|C|
|libnet|`net/libnet`|Reliable Libnet|N/A|S|
|sysnet|`net/sysnet`|Unreliable Sysnet|N/A|C|
|System|`system/vcu108`|Everything|N/A|C|


Status:
- C: on-chip verification
- S: Simulation