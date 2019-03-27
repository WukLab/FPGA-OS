/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */
/*
 * this is file containing definition of buddy cache
 * but it only support up to 64 associativities
 */

#ifndef _BUDDY_H_
#define _BUDDY_H_

#include <fpga/axis_buddy.h>

struct BuddyCacheLine {

	ap_uint<1>			valid;
	ap_uint<ORDER_MAX>	tag;
	ap_uint<8>			children;

	BuddyCacheLine();
} ;

struct BuddyCacheSet
{
	ap_uint<LEVEL_MAX> level;
	ap_uint<BUDDY_SET_TYPE> size;
	BuddyCacheLine lines[BUDDY_SET_SIZE];
	ap_uint<BUDDY_SET_TYPE> rand_counter;

	BuddyCacheSet();
	void count();
};

struct BuddyCacheFreeSet
{
	ap_uint<LEVEL_MAX> level;
	BuddyCacheLine line;
};

/*
 * Buddy Cache table structure
 */
class Buddy
{
public:
	Buddy();
	~Buddy();
	void handler(axis_buddy_alloc& alloc, axis_buddy_alloc_ret& alloc_ret, char* dram);

private:
	unsigned long dram_addr;
	BuddyCacheSet buddy_set[LEVEL_MAX];
	BuddyCacheFreeSet buddy_free_set[LEVEL_MAX];

	RET_STATUS alloc(ap_uint<ORDER_MAX> order, ap_uint<PA_SHIFT>* addr, char* dram);
	RET_STATUS free(ap_uint<ORDER_MAX> order, ap_uint<PA_SHIFT> addr, char* dram);

	void flush_line(BuddyCacheSet& set, ap_uint<LEVEL_MAX> level,
			ap_uint<BUDDY_SET_TYPE> nr_asso, char* dram);
	bool flush_set(BuddyCacheSet& set, ap_uint<LEVEL_MAX> level, ap_uint<3> flush_idx, char* dram);
	void flush_children(BuddyCacheSet& set, ap_uint<BUDDY_SET_TYPE> which, char* dram);
	bool choose_line(BuddyCacheSet& set, ap_uint<BUDDY_SET_TYPE>* nr_asso);

public:
	/*
	 * buddy cache set operations
	 */
	static bool tag_in_cache(BuddyCacheSet& set, ap_uint<ORDER_MAX> tag, ap_uint<BUDDY_SET_TYPE>* nr_asso);
	static bool get_valid_free_set(BuddyCacheSet& set, ap_uint<3> width, ap_uint<BUDDY_SET_TYPE>* nr_asso, ap_uint<3>* idx);

	/*
	 * buddy cache line operations
	 */
	static bool test_valid_bits(BuddyCacheLine& line, ap_uint<3> width, ap_uint<3> idx);
	static void set_clear_bits(BuddyCacheLine& line, ap_uint<3> width, ap_uint<3> idx, bool set_clear);
	static bool get_valid_free_line(BuddyCacheLine& line, ap_uint<3> width, ap_uint<3>* idx);
	static ap_uint<3> get_free_4bit(BuddyCacheLine& line);
	static ap_uint<3> get_free_2bit(BuddyCacheLine& line);
	static ap_uint<3> get_free_1bit(BuddyCacheLine& line);

	/*
	 * some helper functions
	 */
	static ap_uint<LEVEL_MAX> order_to_level(ap_uint<ORDER_MAX> order);
	static ap_uint<3> order_to_width(ap_uint<ORDER_MAX> order);

	static ap_uint<ORDER_MAX> addr_to_tag(ap_uint<PA_SHIFT> addr, ap_uint<LEVEL_MAX> level);
	static ap_uint<3> addr_to_idx(ap_uint<PA_SHIFT> addr, ap_uint<LEVEL_MAX> level);

	static ap_uint<PA_SHIFT> tag_to_addr(ap_uint<ORDER_MAX> tag);
	static ap_uint<ORDER_MAX> tag_to_ancestor_tag(ap_uint<ORDER_MAX> tag, ap_uint<LEVEL_MAX> level);
	static ap_uint<3> tag_to_ancestor_idx(ap_uint<ORDER_MAX> tag, ap_uint<LEVEL_MAX> level);
	static ap_uint<3> tag_to_parent_idx(ap_uint<ORDER_MAX> tag, ap_uint<LEVEL_MAX> level);
	static ap_uint<ORDER_MAX> parenttag_idx_to_tag(ap_uint<ORDER_MAX> parent_tag,
														  ap_uint<LEVEL_MAX> parent_level, ap_uint<3> idx);
	static unsigned long tag_level_to_drambuddy(unsigned long dram_addr, ap_uint<ORDER_MAX> tag, ap_uint<LEVEL_MAX> level);
	static void dram_read(ap_uint<8>* dest, unsigned long src, char* dram);
	static void dram_write(unsigned long dest, ap_uint<8>* src, char* dram);

	/*
	 * some print functions, only available in simulations
	 */
	void dump_buddy_table();
};

#endif /* _BUDDY_H_ */
