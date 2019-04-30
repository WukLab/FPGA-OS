# List of IPs

| IP  | Location| Description| Configurations|Status|
|:--|:--|:--|:--|:--|
|mergesort|`app/mergesort`|HLS Mergesort|N/A|N/A|
|memcached|`app/memcached`|Xilinx KVS|N/A|C|
|Virtual RDM|`app/rdma/rdm_mapping`|Virtualized RDM|N/A|C|
|Segment RDM|`app/rdma/rdm_segment`|Segmented RDM|N/A|C|
|Global Timestamp|`app/timestamp`|Similar to TSC|N/A|C|
|Buddy|`alloc/buddy`|Buddy allocator|`include/fpga/mem_common.h`, `include/fpga/axis_buddy.h`| C |
|Chunk|`alloc/chunk`|Fix-sized chunk allocator|N/A|S|
|AXI Wrapper|`mm/axi_wrapper`|AXI Wrapper for buffering|N/A|C|
|HLS Segment Checking|`mm/hls_mapping`|Segment table checking|`include/fpga/axis_sysmmu.h`|C|
|SysMem|`mm/ip_sysmmu_segment`|Combination of AXI Wrapper and Segment Checking|N/A|C|
|HT mapping|`mm/mapping`|mapping table|`include/fpga/axis_mapping.h`|C|
|libnet|`net/libnet`|Reliable Libnet|`include/fpga/axis_net.h`|S|
|sysnet|`net/sysnet`|Unreliable Sysnet|`include/fpga/axis_net.h`|C|
|System|`system/vcu108`|Everything|N/A|C|


Status:
- C: on-chip verification
- S: Simulation