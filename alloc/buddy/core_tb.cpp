/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "buddy.h"
#include <cmath>
#include <bitset>
#include <vector>
#include <utility>

#define TEST_MACRO 0
#define TEST_PRINT 1

static void order_to_sth()
{
#if TEST_MACRO
	bool success=true;
	ap_uint<LEVEL_MAX> level = 0, exp_level = -1;
	ap_uint<3> width = 0, exp_width;
	std::cout << "\nThree Orders corresponding to one level, aligned to the top orders, and start from 0" << std::endl;
	std::cout << "Within Each Level, width should be 4, 2, 1 respectively with higher order having higher width" << std::endl;
	std::cout << "ORDER_MAX: " << ORDER_MAX << "\tORDER_MAX_PAD: " << ORDER_MAX_PAD << std::endl;
	for (int i = 0, order = ORDER_MAX - 1; order >= 0 ; order--, i++) {
		switch (i % 3) {
		case 0:
			exp_width = 4;
			exp_level++;
			break;
		case 1:
			exp_width = 2;
			break;
		case 2:
			exp_width = 1;
			break;
		default: break;
		}
		level = Buddy::order_to_level(order);
		width = Buddy::order_to_width(order);
#if TEST_PRINT
		std::cout << "ORDER: " << order << "\tLEVEL: " << level << "\tEXP_LEVEL: " << exp_level
					<< "\tWIDTH: " << width << "\tEXP_WIDTH: " << exp_width << std::endl;

#endif
		if (level != exp_level || width != exp_width) {
			success=false;
			break;
		}
	}
#if !TEST_PRINT
	std::cout << "Detail Print is suppressed, enable TEST_PRINT for more info" << std::endl;
#endif
	if (success)
		std::cout << "SUCCESS!!!" << std::endl;
	else
		std::cout << "ERROR!!!!!" << std::endl;
#endif
}

static void tag_addr_idx_translate()
{
#if TEST_MACRO
	ap_uint<PA_SHIFT> addr = 0x3AD4E000;
	ap_uint<ORDER_MAX> tag[LEVEL_MAX], parent_tag1[LEVEL_MAX], parent_tag2[LEVEL_MAX];
	ap_uint<3> idx[LEVEL_MAX], parent_idx[LEVEL_MAX];
	bool success=true;
	std::cout << "\nIDX is the sliding window of address and tag from MSB\n"
				"TAG is everything else from MSB to index of IDX (Exclusive) of corresponding level" << std::endl;

	for (int level = 0; level < LEVEL_MAX; level++) {
		idx[level] = Buddy::addr_to_idx(addr, level);
		tag[level] = Buddy::addr_to_tag(addr, level);
	}
	for (int level = 1; level < LEVEL_MAX; level++) {
		parent_tag1[level] = Buddy::tag_to_ancestor_tag(tag[level], level-1);
		parent_tag2[level] = Buddy::parenttag_idx_to_tag(tag[level-1], level-1, idx[level-1]);
		parent_idx[level] = Buddy::tag_to_ancestor_idx(tag[level], level-1);
	}
	/* checking */
	for (int level = 1; level < LEVEL_MAX; level++) {
		success &= parent_tag1[level] == tag[level-1];
		success &= parent_tag2[level] == tag[level];
		success &= parent_idx[level] == idx[level-1];
	}

#if TEST_PRINT
	std::cout << "ADDR: " << std::bitset<BLOCK_SHIFT>(addr) << std::endl;
	for (int level = 0; level < LEVEL_MAX; level++) {
		if (level > 0) {
			std::cout << "LEVEL:" << level
					<< "  TAG:" << std::bitset<ORDER_MAX>(tag[level])
					<< "  PARENT TAG:" << std::bitset<ORDER_MAX>(parent_tag1[level])
					<< "  TAG(Reconstructed):" << std::bitset<ORDER_MAX>(parent_tag2[level])
					<< "  IDX(from addr):" << std::bitset<3>(idx[level])
					<< "  IDX(from tag):" << std::bitset<3>(parent_idx[level])
					<< std::endl;
		} else {
			std::cout << "LEVEL:" << level
					<< "  TAG:" << std::bitset<ORDER_MAX>(tag[level])
					<< "  PARENT TAG:" << std::setw(ORDER_MAX) << "N/A"
					<< "  TAG(Reconstructed):" << std::setw(ORDER_MAX) << "N/A"
					<< "  IDX(from addr):" << std::bitset<3>(idx[level])
					<< "  IDX(from tag):N/A"
					<< std::endl;
		}
	}
#endif
#if !TEST_PRINT
	std::cout << "Detail Print is suppressed, enable TEST_PRINT for more info" << std::endl;
#endif
	if (success)
		std::cout << "SUCCESS!!!" << std::endl;
	else
		std::cout << "ERROR!!!!!" << std::endl;
#endif
}

static void tag_to_drambuddy()
{
#if TEST_MACRO
	unsigned long dram_addr = 0, addr1, addr2 = 0, expect = 0; // make addr2 = 0 just to make initial test case pass
	bool success=true;
	std::cout << "\nTesting the buddy meta data DRAM calculation" << std::endl;
	for (int level = 1; level < LEVEL_MAX; level++) {
		expect += pow(8, level-1);
		addr1 = Buddy::tag_level_to_drambuddy(dram_addr, 0, level);
#if TEST_PRINT
		std::cout << "LEVEL:" << level << "  EXPECT: " << expect << "  ADDR(First): " << addr1;
#endif
		/* comparison happens between address offset of this level and last level */
		if (expect != addr1 || addr1 - 1 != addr2) {
			success=false;
			break;
		}
		addr2 = Buddy::tag_level_to_drambuddy(dram_addr, ap_uint<ORDER_MAX>(-1), level);
#if TEST_PRINT
		std::cout << "  ADDR(Last): " << addr2 << std::endl;
#endif
	}
#if !TEST_PRINT
	std::cout << "Detail Print is suppressed, enable TEST_PRINT for more info" << std::endl;
#endif
	if (success)
		std::cout << "SUCCESS!!!" << std::endl;
	else
		std::cout << "\tERROR!!!!!" << std::endl;
#endif
}

static void test_cache_line_operation()
{
#if TEST_MACRO
	BuddyCacheLine line;
	ap_uint<3> idx = 0, expect_idx;
	bool ret, expect, success=true;
	std::cout << "\nTesting the buddy cache line operations" << std::endl;

	/* 1. used before initialized as valid, expect fault */
	expect = false;
	ret = Buddy::get_valid_free_line(line, 1, &idx);
	success &= expect == ret;

	/* 2. expect correct */
	expect = true;
	line.valid = true;
	expect_idx = 0;
	ret = Buddy::get_valid_free_line(line, 1, &idx);
	success &= (expect == ret) && (expect_idx == idx);

	/* 3. set the bits specified above */
	Buddy::set_clear_bits(line, 1, idx, true);
	success &= (line.children == 0x1);

	/* 4. expect correct */
	expect = true;
	expect_idx = 2;
	ret = Buddy::get_valid_free_line(line, 2, &idx);
	success &= (expect == ret) && (expect_idx == idx);

	/* 5. set the bits specified above */
	Buddy::set_clear_bits(line, 2, idx, true);
	success &= (line.children == 0xD);

	/* 6. expect correct */
	expect = true;
	expect_idx = 1;
	ret = Buddy::get_valid_free_line(line, 1, &idx);
	success &= (expect == ret) && (expect_idx == idx);

	/* 7. set the bits specified above */
	Buddy::set_clear_bits(line, 1, idx, true);
	success &= (line.children == 0xF);

	/* 7. expect correct */
	expect = true;
	expect_idx = 4;
	ret = Buddy::get_valid_free_line(line, 4, &idx);
	success &= (expect == ret) && (expect_idx == idx);

	/* 8. set the bits specified above */
	Buddy::set_clear_bits(line, 4, idx, true);
	success &= (line.children == 0xFF);

	/* 9. clear the bits */
	Buddy::set_clear_bits(line, 4, 0, false);
	success &= (line.children == 0xF0);

	/* 10. clear the bits */
	Buddy::set_clear_bits(line, 1, 6, false);
	success &= (line.children == 0xB0);

	/* 11. clear the bits, 0 width, no changes */
	Buddy::set_clear_bits(line, 0, 4, false);
	success &= (line.children == 0xB0);

	/* 12. clear the bits */
	Buddy::set_clear_bits(line, 2, 4, false);
	success &= (line.children == 0x80);

	/* 13. clear the bits */
	Buddy::set_clear_bits(line, 1, 7, false);
	success &= (line.children == 0x00);


	if (success)
		std::cout << "SUCCESS!!!" << std::endl;
	else
		std::cout << "ERROR!!!!!" << std::endl;
#endif
}

static void test_cache_set_operation()
{
#if TEST_MACRO
	BuddyCacheSet* set1 = new BuddyCacheSet();
	ap_uint<3> idx = 0;
	ap_uint<BUDDY_SET_TYPE> nr_asso = 0;
	ap_uint<8> result = 0;
	bool ret, success=true;

	set1->size = BUDDY_SET_SIZE;
	set1->level = 2;
	std::cout << "\nTesting the buddy cache set operations" << std::endl;

	/* test get_valid_free_set */
	set1->lines[2].valid = true;
	ret = Buddy::get_valid_free_set(*set1, 4, &nr_asso, &idx);
	success &= (true == ret) && (0 == idx) && (2 == nr_asso);

	/* test tag_in_cache and grandchildren_in_cache */
	for (int i = 3; i < BUDDY_SET_SIZE; i++) {
		set1->lines[i].valid = true;
		set1->lines[i].tag = (ap_uint<3>(i % 5), ap_uint<ORDER_MAX-3>(0));
#if TEST_PRINT
		std::cout << i << "\t" << std::bitset<ORDER_MAX>(set1->lines[i].tag) << std::endl;
#endif
	}
	ret = Buddy::tag_in_cache(*set1, (ap_uint<3>(3), ap_uint<ORDER_MAX-3>(0)), &nr_asso);
	success &= (true == ret) && (3 == nr_asso);

	result = Buddy::grandchildren_in_cache(*set1);
	success &= (result == 0x1F);

	if (success)
		std::cout << "SUCCESS!!!" << std::endl;
	else
		std::cout << "ERROR!!!!!" << std::endl;
#endif
}

static int core_test(OPCODE opcode, ap_uint<PA_SHIFT> addr, ap_uint<ORDER_MAX> order, char* dram, unsigned long* ret_addr)
{
	axis_buddy_alloc alloc;
	axis_buddy_alloc_ret alloc_ret;
	buddy_alloc_if req;
	buddy_alloc_ret_if ret;
	RET_STATUS stat;

	req.opcode = opcode;
	req.order = order;
	req.addr = addr;
	alloc.write(req);

	if (req.opcode == BUDDY_ALLOC)
		std::cout << "[ALLOC]  ";
	else
		std::cout << "[FREE]   ";
	std::cout << "Address:" << std::hex << std::setw(10) << addr
			<< " Order:" << std::setw(ORDER_MAX) << order << std::endl;

	core(alloc, &alloc_ret, dram, &stat);

	if (req.opcode == BUDDY_ALLOC && stat == SUCCESS) {
		ret = alloc_ret.read();
		*ret_addr = (unsigned long)ret.addr;
	} else {
		ret.addr = 0;
	}

	std::cout << "Return Address: " << std::hex << *ret_addr;
#if PA_SHIFT == BLOCK_SHIFT
	std::cout << " == " << std::bitset<PA_SHIFT - BUDDY_MIN_SHIFT>(ret.addr(PA_SHIFT-1, BUDDY_MIN_SHIFT));
#else
	std::cout << " == " << std::bitset<PA_SHIFT - BLOCK_SHIFT>(ret.addr(PA_SHIFT-1, BLOCK_SHIFT));
	std::cout << " " << std::bitset<BLOCK_SHIFT - BUDDY_MIN_SHIFT>(ret.addr(BLOCK_SHIFT-1, BUDDY_MIN_SHIFT));
#endif
	std::cout << " " << std::bitset<BUDDY_MIN_SHIFT>(ret.addr(BUDDY_MIN_SHIFT-1, 0));

	return stat ? -1 : 0;
}

static int print_result(int real, int expect)
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

int main()
{
	char* dram = new char[SIM_DRAM_SIZE]();
	int ret, err_cnt = 0;
	unsigned long addr;
	std::vector< std::pair<unsigned long, int> > vectors, vectors2;

	// helper function test
	order_to_sth();
	tag_addr_idx_translate();
	tag_to_drambuddy();
	test_cache_line_operation();
	test_cache_set_operation();

	/* allocation test */
	ret = core_test(BUDDY_ALLOC, 0, 0, dram, &addr);
	vectors.push_back(std::pair<unsigned long, int>(addr, 0));
	err_cnt += print_result(ret, 0);

	ret = core_test(BUDDY_ALLOC, 0, 0, dram, &addr);
	vectors.push_back(std::pair<unsigned long, int>(addr, 0));
	err_cnt += print_result(ret, 0);

	ret = core_test(BUDDY_ALLOC, 0, 3, dram, &addr);
	vectors.push_back(std::pair<unsigned long, int>(addr, 3));
	err_cnt += print_result(ret, 0);

	ret = core_test(BUDDY_ALLOC, 0, 3, dram, &addr);
	vectors.push_back(std::pair<unsigned long, int>(addr, 3));
	err_cnt += print_result(ret, 0);

	ret = core_test(BUDDY_ALLOC, 0, 3, dram, &addr);
	vectors.push_back(std::pair<unsigned long, int>(addr, 3));
	err_cnt += print_result(ret, 0);

	ret = core_test(BUDDY_ALLOC, 0, 3, dram, &addr);
	vectors.push_back(std::pair<unsigned long, int>(addr, 3));
	err_cnt += print_result(ret, 0);

	ret = core_test(BUDDY_ALLOC, 0, 7, dram, &addr);
	vectors.push_back(std::pair<unsigned long, int>(addr, 7));
	err_cnt += print_result(ret, 0);

	ret = core_test(BUDDY_ALLOC, 0, 12, dram, &addr);
	vectors.push_back(std::pair<unsigned long, int>(addr, 12));
	err_cnt += print_result(ret, 0);

	for (int i = 0; i < ORDER_MAX; i++) {
		ret = core_test(BUDDY_ALLOC, 0, i, dram, &addr);
		if (!ret)
			vectors.push_back(std::pair<unsigned long, int>(addr, i));
		err_cnt += print_result(ret, (i == ORDER_MAX - 1) ? -1 : 0);
	}

	/* Free test */
	addr = 0;
	std::cout << std::endl;
	for (std::vector<std::pair<unsigned long, int>>::iterator i = vectors.begin(); i != vectors.end(); i++) {
		ret = core_test(BUDDY_FREE, i->first, i->second, dram, &addr);
		err_cnt += print_result(ret, 0);
	}

	/* Alloc test 2nd round */
	addr = 0;
	std::cout << std::endl;
	for (std::vector<std::pair<unsigned long, int>>::reverse_iterator i = vectors.rbegin(); i != vectors.rend(); i++) {
		ret = core_test(BUDDY_ALLOC, 0, i->second, dram, &addr);
		vectors2.push_back(std::pair<unsigned long, int>(addr, i->second));
		err_cnt += print_result(ret, 0);
	}

	/* Free test 2nd round */
	addr = 0;
	std::cout << std::endl;
	for (std::vector<std::pair<unsigned long, int>>::iterator i = vectors2.begin(); i != vectors2.end(); i++) {
		ret = core_test(BUDDY_FREE, i->first, i->second, dram, &addr);
		err_cnt += print_result(ret, 0);
	}

	vectors.clear();
	vectors2.clear();

	return err_cnt;
}

