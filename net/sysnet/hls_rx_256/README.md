# SysNet RX 256b version

The current version of code is built based on header format:
```
|Eth Header|App Header| pad |
0         112        X     255
```

Header format matters because we need to know where to extract the `APP_ID`.
If we have a change, remind to change both `top_256.cpp` and `tb_256.cpp`.

## Configurations
`NR_OUTPUTS`: defines how many downstreams IPs can be connected.
