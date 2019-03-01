#include <stdlib.h>
#include <ctime>
#include <fpga/axis_sysmmu_ctrl.h>
#include <fpga/axis_sysmmu_data.h>
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

static int data_test(ap_uint<PA_SHIFT> addr, ap_uint<PID_SHIFT> pid,
					ap_uint<PA_SHIFT> size, ACCESS_TYPE rw)
{
	axis_sysmmu_data datapath;
	axis_sysmmu_ctrl ctrlpath_dummy;
	sysmmu_data_if req;
	RET_STATUS result, dummy;

	req.addr = addr;
	req.pid = pid;
	req.size = size;
	req.rw = rw;
	datapath.write(req);

	std::cout << "[ACCESS] Address:" << std::hex << std::setw(10) << req.addr
			<< " IDX:" << std::dec << std::setw(3) << BLOCK_IDX(req.addr)
			<< " PID:" <<  req.pid
			<< " Size:" << std::hex << std::setw(10) << req.size
			<< " RW:" << std::dec << req.rw;

	core(ctrlpath_dummy, datapath, &dummy, &result);

	return result ? -1 : 0;
}

static int ctrl_test(OPCODE opcode, ap_uint<PA_SHIFT> addr, ap_uint<PID_SHIFT> pid, ACCESS_TYPE rw)
{
	axis_sysmmu_data datapath_dummy;
	axis_sysmmu_ctrl ctrlpath;
	sysmmu_ctrl_if req;
	RET_STATUS dummy, result;

	req.opcode = opcode;
	req.addr = addr;
	req.pid = pid;
	req.rw = rw;
	ctrlpath.write(req);

	if (req.opcode == SYSMMU_ALLOC)
		std::cout << "[ALLOC]  ";
	else
		std::cout << "[FREE]   ";
	std::cout << "Address:" << std::hex << std::setw(10) << req.addr
			<< " IDX:" << std::dec << std::setw(3) << BLOCK_IDX(req.addr)
			<< " PID:" << req.pid
			<< " Size:" << std::setw(10) << "N/A"
			<< " RW:" << req.rw;

	core(ctrlpath, datapath_dummy, &result, &dummy);

	return result ? -1 : 0;
}

int print_result(int real, int expect)
{
	std::cout << " RET: " << std::setw(2) << real
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
	ap_uint<PA_SHIFT> rand1, rand2;

	/* Random address generation */
	do {
		srand(clock());
		rand1 = rand() % SIZE(PA_SHIFT);
	} while (rand1 < (1UL << (BLOCK_SHIFT + 1)) ||
			 rand1 > (1UL << PA_SHIFT) - (1UL << BLOCK_SHIFT));
	do {
		srand(clock());
		rand2 = rand() % SIZE(PA_SHIFT);
	} while (rand2 < (1UL << (BLOCK_SHIFT + 1)) ||
			 rand2 > (1UL << PA_SHIFT) - (1UL << BLOCK_SHIFT) ||
			 ALIGN_DOWN(rand2, BLOCK_SIZE) == ALIGN_DOWN(rand1, BLOCK_SIZE));

	/* ALLOC */
	ret = ctrl_test(SYSMMU_ALLOC, 0, 123, MEMWIRTE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(SYSMMU_ALLOC, 1UL << BLOCK_SHIFT, 123, MEMWIRTE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(SYSMMU_ALLOC, (1UL << PA_SHIFT) - 1, 123, MEMWIRTE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(SYSMMU_ALLOC, rand1, 456, MEMREAD);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(SYSMMU_ALLOC, rand2, 456, MEMREAD);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(SYSMMU_ALLOC, 0, 123, MEMWIRTE);
	err_cnt += print_result(ret, -1);

	ret = ctrl_test(SYSMMU_ALLOC, rand1, 123, MEMWIRTE);
	err_cnt += print_result(ret, -1);

	/* ACCESS */
	ret = data_test(0, 123, 1, MEMWIRTE);
	err_cnt += print_result(ret, 0);

	ret = data_test((1UL << PA_SHIFT) - 1, 123, 1, MEMWIRTE);
	err_cnt += print_result(ret, 0);

	ret = data_test(rand1, 456, 1, MEMREAD);
	err_cnt += print_result(ret, 0);

	ret = data_test(rand2, 456, 1, MEMREAD);
	err_cnt += print_result(ret, 0);

	/* wrong PID */
	ret = data_test(rand1, 123, 1, MEMREAD);
	err_cnt += print_result(ret, -1);

	/* wrong permission */
	ret = data_test(rand2, 456, 1, MEMWIRTE);
	err_cnt += print_result(ret, -1);

	ret = data_test(0, 123, 1UL << (BLOCK_SHIFT + 1), MEMWIRTE);
	err_cnt += print_result(ret, 0);

	/* invalid address */
	ret = data_test(0, 123, (1UL << (BLOCK_SHIFT + 1)) + 1, MEMWIRTE);
	err_cnt += print_result(ret, -1);

	/* FREE */
	ret = ctrl_test(SYSMMU_FREE, 0, 123, MEMWIRTE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(SYSMMU_FREE, 1UL << BLOCK_SHIFT, 123, MEMWIRTE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(SYSMMU_FREE, (1UL << PA_SHIFT) - 1, 123, MEMWIRTE);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(SYSMMU_FREE, rand1, 456, MEMREAD);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(SYSMMU_FREE, rand2, 456, MEMREAD);
	err_cnt += print_result(ret, 0);

	ret = ctrl_test(SYSMMU_FREE, 0, 123, MEMWIRTE);
	err_cnt += print_result(ret, -1);

	ret = ctrl_test(SYSMMU_FREE, rand1, 123, MEMWIRTE);
	err_cnt += print_result(ret, -1);

	/* USE AFTER FREE */
	ret = data_test(rand1, 456, 1, MEMREAD);
	err_cnt += print_result(ret, -1);

	ret = data_test(rand2, 456, 1, MEMREAD);
	err_cnt += print_result(ret, -1);

	return err_cnt;
}
