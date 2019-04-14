# Mapping Translation IP

## Introduction

This hash is intended to translate from an input `X` to output `Y`.
This IP is not just a single HLS IP or a Vivado IP, it consists of
three major parts:

- HLS-based Mapping Translation
- HLS-based BRAM HashTable
- Top-level integration with Datamover

The first small HLS-based Mapping Translation is under `hls_mapping`.
This IP will take input requests, perform BRAM/DRAM access,
and key comparision. After that, it will output the results.

The second small HLS-based BRAM HashtTable just serves as the cached
hashtable in BRAM. The reason to separate it from the first small IP
is due to the limitation of HLS Dataflow, which only permits Read-After-Write
accessing sequence. While in this translation, we obviously will
do Read first, then maybe write back something. This small IP is following
the Datamover interface, so it can be replaced by a Datamover if needed.

The top-level integration put the above two small IPs together along with
some other IPs, such as Datamover and FIFO buffer.

## Configurations

There are only couple configurations matter, you can find them under
`hls_mapping/hash.hpp` and `include/fpga/axis_mapping.hpp`. All configurations
are shared across the two HLS-based IPs:

- `NR_BITS_BUCKET`: the number of bits of a single hash bucket
- `NR_BITS_KEY` and `NR_BITS_VAL`: the width of key/value within bucket
- `NR_SLOTS_PER_BUCKET`: the number of key/value pairs within a single bucket
- `NR_HT_BUCKET_DRAM_SHIFT`: determine the size of DRAM hashtable
- `NR_HT_BUCKET_BRAM_SHIFT`: determine the size of BRAM hashtable
- `MAPPING_TABLE_ADDRESS_BASE`: this is the base physical DRAM address of the hashtable.
   You should configure it in a way that it won't have conflict with any other IPs that
   use DRAM directly (e.g., Buddy Allocator).

## Hack Note

- The reason to have `in_read` and `in_write` is to serve concurrent translation
  request from AXI transactions. Even though we could take both requests in at
  the same time, in fact they will executed sequentially within pipeline.
- This mapping currently only support fixed Key and Value. And everything is inlined.
  Extension is doable: replacing the original 32b with DRAM address.
- Chaining is not implemented
