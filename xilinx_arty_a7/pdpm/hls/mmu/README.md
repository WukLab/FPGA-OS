# Memory Management Unit

Each MMU instance should have a AXI slave interface used by upstream IP,
and a AXI master interface to talk with downstream IP.

MMU will translate the Virtual Address within Read Address and Write Address channels.
Mostly, the translation will be larger than one cycle, that means we need to cache
some AXI states.

Goal is to keep II=1.

Internally, MMU can hook with different translation units, for example segment and paging.
The interface to translation is `AXI Stream`. Design is not finalized. This is an initial thought.
`Segment` folder describes AXI-Stream based translation service.
`paging_generic` should have some generic paging based code, then we can leverage this to
have cutomized page size, such as 2K, 4K, etc.

Maybe the AXI state caching has to be implemented in Verilog?
