/*
 * Copyright (c) 2019, WukLab, Purdue University.
 */

#include <ctime>
#include <fpga/log2.h>
#include "sysmmu.h"

/*
 * Test Cases:
 * 1. Alloc: lowest, highest possible addr, random addr; Expect: Correct
 * 2. Alloc: on existing slot; Expect: Error
 * 3. Access: Single address, same pid, lowest, highest possible addr, random addr; Expect: Correct
 * 4. Access: Single address, diff pid; Expect: Error
 * 5. Access: Single address, diff permission; Expect: Error
 * 6. Access: Multiple address, all allocated; Expect: Correct
 * 7. Access: Multiple address, some allocated, some not; Expect: Error
 * 8. Free: Free lowest, highest possible addr, random addr; Expect: Correct
 * 9. Free: Double Free; Expect: Error
 * 10. Access: Single address but not allocated; Expect: Error
 */

int data_test(ap_uint<PA_WIDTH> addr, ap_uint<PID_WIDTH> pid,
		ap_uint<PA_WIDTH> size, ap_uint<1> rw)
{
	struct sysmmu_indata in_rd = {0,0,0,0}, in_wr = {0,0,0,0};
	struct sysmmu_outdata out_rd = {0,0}, out_wr = {0,0};
	hls::stream<struct sysmmu_ctrl_if> ctrlpath_dummy;
	ap_uint<1> result, dummy;

	if (rw == WRITE) {
		/* write */
		in_wr.in_addr = addr;
		in_wr.pid = pid;

		in_wr.in_len = size >> 7;
		if (size(6, 0) > 0)
			in_wr.in_len++;

		if (in_wr.in_len == 1)
			in_wr.in_size = order_base_2<PA_WIDTH>(ap_uint<PA_WIDTH>(size(7,0) >> 1));
		else
			in_wr.in_size = 7;

		std::cout << "[ACCESS] Address:" << std::hex << std::setw(10) << in_wr.in_addr
				<< " IDX:" << std::dec << std::setw(3) << CHUNK_IDX(in_wr.in_addr)
				<< " PID:" <<  in_wr.pid
				<< " AXI Size passed in:" << std::hex << std::setw(16)
				<< (ap_uint<16>(in_wr.in_len) << ap_uint<16>(in_wr.in_size))
				<< " Real Size:" << std::hex << std::setw(10) << size
				<< " RW:" << std::dec << rw;
	} else {
		/* read */
		in_rd.in_addr = addr;
		in_rd.pid = pid;

		in_rd.in_len = size >> 7;
		if (size(6, 0) > 0)
			in_rd.in_len++;

		if (in_rd.in_len == 1)
			in_rd.in_size = order_base_2<PA_WIDTH>(ap_uint<PA_WIDTH>(size(7,0) >> 1));
		else
			in_rd.in_size = 7;

		std::cout << "[ACCESS] Address:" << std::hex << std::setw(10) << in_rd.in_addr
				<< " IDX:" << std::dec << std::setw(3) << CHUNK_IDX(in_rd.in_addr)
				<< " PID:" <<  in_rd.pid
				<< " AXI Size passed in:" << std::hex << std::setw(16)
				<< (ap_uint<16>(in_rd.in_len) << ap_uint<16>(in_rd.in_size))
				<< " Real Size:" << std::hex << std::setw(10) << size
				<< " RW:" << std::dec << rw;
	}

	mm_segment_top(ctrlpath_dummy, &dummy, in_rd, &out_rd, in_wr, &out_wr);

	if (rw) {
		return out_wr.drop ? -1 : 0;
	} else {
		return out_rd.drop ? -1 : 0;
	}
}

int ctrl_test(ap_uint<1> opcode, ap_uint<PA_WIDTH> addr, ap_uint<PID_WIDTH> pid, ap_uint<1> rw)
{
	struct sysmmu_indata in_rd = {0,0,0,0}, in_wr = {0,0,0,0};
	struct sysmmu_outdata out_rd = {0,0}, out_wr = {0,0};
	hls::stream<struct sysmmu_ctrl_if> ctrlpath;
	struct sysmmu_ctrl_if req;
	ap_uint<1> result;

	req.opcode = opcode;
	req.idx = CHUNK_IDX(addr);
	req.pid = pid;
	req.rw = rw;
	ctrlpath.write(req);

	if (req.opcode == CHUNK_ALLOC)
		std::cout << "[ALLOC]  ";
	else
		std::cout << "[FREE]   ";
	std::cout << "Address:" << std::hex << std::setw(10) << addr
			<< " IDX:" << std::dec << std::setw(3) << req.idx
			<< " PID:" << req.pid
			<< " AXI Size passed in:" << std::setw(16) << "N/A"
			<< " Real Size:" << std::hex << std::setw(10) << "N/A"
			<< " RW:" << std::dec << req.rw;


	mm_segment_top(ctrlpath, &result, in_rd, &out_rd, in_wr, &out_wr);

	return result ? -1 : 0;
}

int print_result(int real, int expect)
{
	std::cout << " RET: " << std::setw(2) << std::dec << real
			  << " EXPT: " << std::setw(2) << expect;
	if (real == expect) {
		std::cout << "  SUCCESS!!" << std::endl;
		return 0;
	}
	else {
		std::cout << "  FAILED!!" << std::endl;
		return 1;
	}
}

int main(void)
{
	int ret, err_cnt = 0;
	ap_uint<PA_WIDTH> rand1, rand2;

	/* Random address generation */
	do {
		srand(clock());
		rand1 = rand() % SIZE(PA_WIDTH);
	} while (rand1 < (1UL << (CHUNK_SHIFT + 1)) ||
			 rand1 > (1UL << PA_WIDTH) - (1UL << CHUNK_SHIFT));
	do {
		srand(clock());
		rand2 = rand() % SIZE(PA_WIDTH);
	} while (rand2 < (1UL << (CHUNK_SHIFT + 1)) ||
			 rand2 > (1UL << PA_WIDTH) - (1UL << CHUNK_SHIFT) ||
			 ALIGN_DOWN(rand2, CHUNK_SIZE) == ALIGN_DOWN(rand1, CHUNK_SIZE));

	/* ALLOC */
	ret = ctrl_test(CHUNK_ALLOC, 0, 12, WRITE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(CHUNK_ALLOC, 1UL << CHUNK_SHIFT, 12, WRITE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(CHUNK_ALLOC, (1UL << PA_WIDTH) - 1, 12, WRITE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(CHUNK_ALLOC, rand1, 45, READ);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(CHUNK_ALLOC, rand2, 45, READ);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(CHUNK_ALLOC, 0, 12, WRITE);
	err_cnt += print_result(ret, -1);

	ret = ctrl_test(CHUNK_ALLOC, rand1, 12, WRITE);
	err_cnt += print_result(ret, -1);

	/* ACCESS */
	ret = data_test(0, 12, 1, WRITE);
	err_cnt += print_result(ret, 0);

	ret = data_test((1UL << PA_WIDTH) - 1, 12, 1, WRITE);
	err_cnt += print_result(ret, 0);

	ret = data_test(rand1, 45, 1, READ);
	err_cnt += print_result(ret, 0);

	ret = data_test(rand2, 45, 1, READ);
	err_cnt += print_result(ret, 0);

	/* wrong PID */
	ret = data_test(rand1, 12, 1, READ);
	err_cnt += print_result(ret, -1);

	/* wrong permission */
	ret = data_test(rand2, 45, 1, WRITE);
	err_cnt += print_result(ret, -1);

	ret = data_test((1UL << (CHUNK_SHIFT + 1)) - (1UL << (14)),
			12, 1UL << 14, WRITE);
	err_cnt += print_result(ret, 0);

	/* invalid address */
	ret = data_test((1UL << (CHUNK_SHIFT + 1)) - (1UL << (14)),
				12, (1UL << 14) + 128, WRITE);
	err_cnt += print_result(ret, -1);

	/* FREE */
	ret = ctrl_test(CHUNK_FREE, 0, 12, WRITE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(CHUNK_FREE, 1UL << CHUNK_SHIFT, 12, WRITE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(CHUNK_FREE, (1UL << PA_WIDTH) - 1, 12, WRITE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(CHUNK_FREE, rand1, 45, READ);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(CHUNK_FREE, rand2, 45, READ);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(CHUNK_FREE, 0, 12, WRITE);
	err_cnt += print_result(ret, -1);

	ret = ctrl_test(CHUNK_FREE, rand1, 12, WRITE);
	err_cnt += print_result(ret, -1);

	/* USE AFTER FREE */
	ret = data_test(rand1, 45, 1, READ);
	err_cnt += print_result(ret, -1);

	ret = data_test(rand2, 45, 1, READ);
	err_cnt += print_result(ret, -1);

	return err_cnt;
}
