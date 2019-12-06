# HLS-based Mapping Translation

Last Updated: Nov 6, 2019

# Introduction

This is the single HLS IP for translating an input `X` to output `Y`. The following functions are implemented.

- Setting key-value pair in HashTable with R/W permission
- Translating input to output and performing permission check
- Chaining HashTable in DRAM

Key-value pairs are stored in 512bit hash buckets. Each hash bucket has 7 32bit-to-32bit key-value pairs (each pair has a permission bit), a bitmap, a 26bit chaining address and a 1bit chaining flag.

This IP need to connect to an allocator. If a hash bucket in DRAM is full, when new setting request hit that hash bucket, this IP will call the allocator to allocate a new bucket to store more key-value pairs.

TODO:

- Need to implement policy for evicting entry from BRAM
- Should move dependency checking forward
- Need to implement delete entries
