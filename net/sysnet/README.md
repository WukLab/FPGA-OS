# SysNet

Code written in HLS, and top-level module exported by Vivado.

- RX HLS
	- Etherner/IP Decap
	- Dispatcher to different LibNets
- TX HLS
	- Arbiter
	- Ethernet/IP Encap
- Sys Vivado
	- Top-level SysNet
	- Combined RX and TX
