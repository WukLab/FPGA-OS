/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include "buddy.h"
#include <iostream>

using namespace hls;
using namespace std;

int main() {
	stream<struct buddy_alloc_if> buddy_req("req");
	stream<struct buddy_alloc_ret_if> buddy_ret("ret");
	stream<unsigned long> init;
	char *dram = new char[BUDDY_USER_OFF]();

	struct buddy_alloc_if table_req, metadata_req;
	struct buddy_alloc_ret_if table_ret, metadata_ret;
	unsigned long init_addr = BUDDY_META_OFF;
	cout << hex;
	cout << "start addr: " << init_addr << endl;
	cout << "user off: " << init_addr + BUDDY_META_SIZE << endl;

	init.write(init_addr);
	table_req.opcode = BUDDY_ALLOC;
	table_req.order = 16 - 8;
	cout << "alloc request order: " << table_req.order.to_uint() << endl;
	buddy_req.write(table_req);

	buddy_allocator(buddy_req, buddy_ret, init, dram);

	table_ret = buddy_ret.read();
	cout << "[stat: " << table_ret.stat.to_uint()
	     << ", addr: " << table_ret.addr.to_uint() << "]\n";

	metadata_req.opcode = BUDDY_ALLOC;
	metadata_req.order = 22 - 8;
	cout << "alloc request order: " << metadata_req.order.to_uint() << endl;
	buddy_req.write(metadata_req);

	buddy_allocator(buddy_req, buddy_ret, init, dram);

	metadata_ret = buddy_ret.read();
	cout << "[stat: " << metadata_ret.stat.to_uint()
	     << ", addr: " << metadata_ret.addr.to_uint() << "]\n";

	table_req.opcode = BUDDY_FREE;
	table_req.addr = table_ret.addr;
	buddy_req.write(table_req);

	buddy_allocator(buddy_req, buddy_ret, init, dram);

	table_ret = buddy_ret.read();
	cout << "[stat: " << table_ret.stat.to_uint() << "]\n";

	metadata_req.opcode = BUDDY_FREE;
	metadata_req.addr = metadata_ret.addr;
	buddy_req.write(metadata_req);

	buddy_allocator(buddy_req, buddy_ret, init, dram);

	metadata_ret = buddy_ret.read();
	cout << "[stat: " << metadata_ret.stat.to_uint() << "]\n";

	return 0;
}
