#include <stdlib.h>
#include <ctime>
#include "chunk_alloc.h"

enum {
	SUCCESS = 0,
	ERROR = 1,
};

/*
 * Test Cases:
 * 1. Alloc: from 1 all the way to the last one; Expect: Correct
 * 2. Alloc: alloc more after full; Expect: Error
 * 3. Free:  Randomly free some chunk, with wrong PID; Expect: Error
 * 4. Free:  Randomly free some chunk, with wrong permission; Expect: Correct
 * 5. Free:  Randomly free some chunk; Expect: Correct
 * 6. Alloc: Reallocate what's free above; Expect: Correct
 * 7. Free:  Free Everything; Expect: Correct
 * 8. Free:  Double Free; Expect: Error
 */

static int test(ap_uint<1> opcode, ap_uint<PA_WIDTH> addr, ap_uint<PID_WIDTH> pid, ap_uint<1> rw,
		ap_uint<1> expt_stat, ap_uint<1> expt_sysmmu_stat, ap_uint<PA_WIDTH> expt_addr,
		bool expt_req2sysmmu)
{
	hls::stream<struct sysmmu_ctrl_if> ctrl;
	hls::stream<sysmmu_alloc_if> alloc;
	hls::stream<sysmmu_alloc_ret_if> ret_fifo;
	sysmmu_ctrl_if ctrl_req;
	sysmmu_alloc_if req;
	sysmmu_alloc_ret_if ret;
	ap_uint<1> stat = SUCCESS;

	req.opcode = opcode;
	req.addr = addr;
	req.pid = pid;
	req.rw = rw;
	alloc.write(req);

	if (req.opcode == CHUNK_ALLOC)
		std::cout << "[ALLOC]  ";
	else
		std::cout << "[FREE]   ";
	std::cout << "Address:" << std::hex << std::setw(10) << req.addr
			<< " IDX:" << std::dec << std::setw(3) << CHUNK_IDX(req.addr)
			<< " PID:" << req.pid
			<< " RW:" << req.rw;

	chunk_alloc(alloc, ret_fifo, ctrl, expt_sysmmu_stat, &stat);

	if (expt_stat != SUCCESS) {
		if (!ctrl.empty())
			ctrl_req = ctrl.read();
		return stat ? -1 : 0;
	}

	if (expt_req2sysmmu) {
		if (!ctrl.empty())
			ctrl_req = ctrl.read();
	}

	if (!ret_fifo.empty())
		ret = ret_fifo.read();

	return 0;
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
	ap_uint<PA_WIDTH> rand1, rand2, tmp;

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
	/* let rand1 store smaller random number */
	if (rand2 < rand1) {
		tmp = rand2;
		rand2 = rand1;
		rand1 = tmp;
	}

	/* case 1 */
	for (int i = 0; i < TABLE_SIZE; i++) {
		ret = test(CHUNK_ALLOC, ADDR(i, CHUNK_SHIFT), 123, WRITE,
				SUCCESS, SUCCESS, ADDR(i, CHUNK_SHIFT), true);
		err_cnt += print_result(ret, 0);
	}

	/* case 2 */
	ret = test(CHUNK_ALLOC, 0, 123, WRITE, ERROR, ERROR, 0, false);
	err_cnt += print_result(ret, -1);

	/* case 3 */
	ret = test(CHUNK_FREE, rand1, 456, WRITE, ERROR, ERROR, 0, true);
	err_cnt += print_result(ret, -1);

	/* case 4 */
	ret = test(CHUNK_FREE, rand1, 123, READ, SUCCESS, SUCCESS, 0, true);
	err_cnt += print_result(ret, 0);

	/* case 5 */
	ret = test(CHUNK_FREE, rand2, 123, WRITE, SUCCESS, SUCCESS, 0, true);
	err_cnt += print_result(ret, 0);

	/* case 6 */
	ret = test(CHUNK_ALLOC, 0, 123, WRITE, SUCCESS, SUCCESS,
			(ap_uint<PA_WIDTH>)ALIGN_DOWN(rand1, CHUNK_SIZE), true);
	err_cnt += print_result(ret, 0);
	ret = test(CHUNK_ALLOC, 0, 123, WRITE, SUCCESS, SUCCESS,
			(ap_uint<PA_WIDTH>)ALIGN_DOWN(rand2, CHUNK_SIZE), true);
	err_cnt += print_result(ret, 0);

	/* case 7 */
	for (int i = 0; i < TABLE_SIZE ; i++) {
		ret = test(CHUNK_FREE, ADDR(i, CHUNK_SHIFT), 123, WRITE,
				SUCCESS, SUCCESS, ADDR(i, CHUNK_SHIFT), true);
		err_cnt += print_result(ret, 0);
	}

	/* case 8 */
	ret = test(CHUNK_FREE, rand1, 123, WRITE, ERROR, ERROR, 0, false);
	err_cnt += print_result(ret, -1);

	return err_cnt;
}
