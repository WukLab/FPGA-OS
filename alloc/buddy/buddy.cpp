/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */



#include <cassert>
#include <cstring>
#include <iostream>
#include <bitset>
#include <fpga/log2.h>
#include "buddy.h"

#define BUDDY_DEBUG_DUMP 0

/*
 * some terminology used in this code
 * level: index of buddy caches, used to select a single set of whole caches
 * nr_asso: the number of associativity, used to select a single line from a set
 * idx:	the number of bit, used as a index of bit in a cache line
 */
const int LOOP_LEVEL_MAX = LEVEL_MAX;
const int UNROLL_FACTOR = BUDDY_SET_SIZE >> 2;

/*
 * put constructor on the top for modify hls pragma
 */
Buddy::Buddy()
{
	const ap_uint<32> metadata_size = (1 << (3 * LEVEL_MAX)) / 7;
	const ap_uint<32> metadata_order =order_base_2<32>(LENGTH_TO_ORDER(metadata_size));
	const ap_uint<LEVEL_MAX> metadata_level = order_to_level(metadata_order);
	const ap_uint<3> metadata_width = order_to_width(metadata_order);

	dram_addr = 0;
	INIT_LOOP:
	for (int i = 0; i < LEVEL_MAX; i++) {
		buddy_set[i].level = i;
		buddy_set[i].size = (1 << 3*i) < BUDDY_SET_SIZE ? (1 << 3*i) : BUDDY_SET_SIZE;
		buddy_set[i].rand_counter = 0;
		buddy_free_set[i].level = i;

		/* reserve space for buddy meta data */
		if (i <= metadata_level) {
			buddy_set[i].lines[0].valid = 1;
			buddy_set[i].lines[0].tag = 0;
			if (i == metadata_level) {
				set_clear_bits(buddy_set[i].lines[0], metadata_width, 0, true);
			} else {
				set_clear_bits(buddy_set[i].lines[0], 1, 0, true);
			}
		}
	}

#if BUDDY_DEBUG_DUMP
	std::cout << "Meta data Size: " << std::bitset<32>(metadata_size)
		<< " Meta data Order: " << metadata_order
		<< " Meta data Level: " << metadata_level
		<< " Meta data Width: " << metadata_width
		<< std::endl;
#endif
	dump_buddy_table();
}

BuddyCacheSet::BuddyCacheSet()
{
#pragma HLS RESOURCE variable=size core=ROM_nP_LUTRAM
#pragma HLS RESOURCE variable=level core=ROM_nP_LUTRAM
}

BuddyCacheLine::BuddyCacheLine()
{
#pragma HLS RESOURCE variable=valid core=RAM_S2P_LUTRAM
	valid = ap_uint<1>(0);
	tag = ap_uint<ORDER_MAX>(0);
	children = ap_uint<8>(0);
}

void Buddy::handler(axis_buddy_alloc& alloc, axis_buddy_alloc_ret& alloc_ret, char* dram)
{
	/*
	 * Don't do axi stream empty check, non-blocking will cause co-sim to hang
	 * just make sure you have data and then call this function during simulation
	 */
	buddy_alloc_if req = alloc.read();
	buddy_alloc_ret_if ret;
	ap_uint<8> test;
	REQ_DISPATCH:
	switch (req.opcode) {
	case BUDDY_ALLOC:
		ret.stat = Buddy::alloc(req.order, &ret.addr, dram);
		if (ret.stat == ERROR)
			ret.addr = 0;
		alloc_ret.write(ret);
		break;
	case BUDDY_FREE:
		ret.stat = Buddy::free(req.order, req.addr, dram);
		break;
	default:
		ret.stat = ERROR;
	}
	/*
	 * only active during simulation
	 */
	dump_buddy_table();
}


RET_STATUS Buddy::alloc(ap_uint<ORDER_MAX> order, ap_uint<PA_SHIFT>* addr, char* dram)
{
	// 1. get order level
	// 2. if tag doesn't exist, ask parent iteratively
	// 3. flush corresponding part to memory
	// 4. load corresponding part from memory
	// 5. calculate address
	// 6. return
	if (order < 0 || order >= ORDER_MAX - 1)
		return ERROR;


	ap_uint<BUDDY_SET_TYPE> nr_asso = 0;
	ap_uint<3> idx = 0;
	ap_uint<3> width = order_to_width(order);
	ap_uint<LEVEL_MAX> req_level = order_to_level(order), start_level, i;
	ap_uint<ORDER_MAX> tag;
	bool no_flush, available;
	*addr = 0;
#if BUDDY_DEBUG_DUMP
	std::cout << "LEVEL: " << req_level << " WIDTH: " << width << std::endl;
#endif

	/* find a valid cache line with lowest level */
	ALLOC_VALID_LINE_LOOK_UP:
	for (start_level = req_level; start_level >= 0; start_level--) {
#pragma HLS loop_tripcount min=1 max=LOOP_LEVEL_MAX
		if (start_level == req_level)
			available = get_valid_free_set(buddy_set[start_level], width, &nr_asso, &idx);
		else
			available = get_valid_free_set(buddy_set[start_level], 1, &nr_asso, &idx);

		if (available) {
			break;
		}
	}
	/* not available, memory full */
	if (!available)
		return ERROR;

	/* set the valid lines */
	if (start_level == req_level) {
		set_clear_bits(buddy_set[start_level].lines[nr_asso], width, idx, true);
	} else {
		set_clear_bits(buddy_set[start_level].lines[nr_asso], 1, idx, true);
	}
	tag = parenttag_idx_to_tag(buddy_set[start_level].lines[nr_asso].tag, start_level, idx);
	/* flush back to DRAM if it's full after prepare tag */
	if (buddy_set[start_level].lines[nr_asso].children == 0xFF)
		flush_line(buddy_set[start_level], start_level, nr_asso, dram);
	/* load from memory and do some operations */
	ALLOC_CACHE_LOAD:
	for (i = start_level + 1; i <= req_level; i++) {
#pragma HLS loop_tripcount min=0 max=LOOP_LEVEL_MAX-1
		no_flush = Buddy::choose_line(buddy_set[i], &nr_asso);
		if (!no_flush)
			flush_line(buddy_set[i], i, nr_asso, dram);

		/* load from memory */
		dram_read(&(buddy_set[i].lines[nr_asso].children), tag_level_to_drambuddy(dram_addr, tag, i), dram);

		/* fill meta data */
		buddy_set[i].lines[nr_asso].tag = tag;
		buddy_set[i].lines[nr_asso].valid = 1;	/* set valid before check which index to go */
		if (i == req_level) {
			get_valid_free_line(buddy_set[i].lines[nr_asso], width, &idx);
			set_clear_bits(buddy_set[i].lines[nr_asso], width, idx, true);
		} else {
			get_valid_free_line(buddy_set[i].lines[nr_asso], 1, &idx);
			set_clear_bits(buddy_set[i].lines[nr_asso], 1, idx, true);
		}

		tag = parenttag_idx_to_tag(buddy_set[i].lines[nr_asso].tag, i, idx);

		/* flush back to DRAM if it's full after prepare tag */
		if (buddy_set[i].lines[nr_asso].children == 0xFF)
			flush_line(buddy_set[i], i, nr_asso, dram);
	}

	*addr = tag_to_addr(tag);

	return SUCCESS;
}

RET_STATUS Buddy::free(ap_uint<ORDER_MAX> order, ap_uint<PA_SHIFT> addr, char* dram)
{
	// 1. get tag, level, and index based on addr and order
	// 2. if tag doesn't exist, ask parent level iteratively
	// 3. flush corresponding part to memory
	// 4. load corresponding part from memory
	// 5. calculate address
	// 6. return
	if (order < 0 || order >= ORDER_MAX - 1)
		return ERROR;

	ap_uint<LEVEL_MAX> req_level = order_to_level(order);
	ap_uint<3> width = order_to_width(order);
	ap_uint<ORDER_MAX> tag;
	ap_uint<BUDDY_SET_TYPE> nr_asso[LEVEL_MAX] = {0};
	ap_uint<LEVEL_MAX> in_cache = ap_uint<LEVEL_MAX>(-1);
	bool valid_req = false, cont = true;
#if BUDDY_DEBUG_DUMP
	std::cout << "LEVEL: " << req_level << " ADDR: " << addr << " WIDTH: " << width << std::endl;
#endif

	// check requested free has been assigned correctly, load part not in cache from memory
	for (int i = req_level; i >= 0; i--) {
#pragma HLS loop_tripcount min=1 max=LOOP_LEVEL_MAX
		ap_uint<3> width_i = (i == req_level) ? width : ap_uint<3>(1);
		ap_uint<3> idx_i = addr_to_idx(addr, i);

#if BUDDY_DEBUG_DUMP
	std::cout << "LEVEL: " << i << " IDX: " << idx_i << " WIDTH: " << width_i << std::endl;
#endif
		tag = addr_to_tag(addr, i);
		in_cache[i] = tag_in_cache(buddy_set[i], tag, &(nr_asso[i]));
		if (in_cache[i]) {
			// this one should definitely in cache, otherwise, something goes wrong
			valid_req = test_valid_bits(buddy_set[i].lines[nr_asso[i]], width_i, idx_i);
		} else {
			// everything not in cache, load it in free_set
			dram_read(&(buddy_free_set[i].line.children), tag_level_to_drambuddy(dram_addr, tag, i), dram);
			buddy_free_set[i].line.tag = tag;
			buddy_free_set[i].line.valid = 1;
			valid_req = test_valid_bits(buddy_free_set[i].line, width_i, idx_i);
		}
		if (!valid_req)
			break;
	}
	if (!valid_req)
		return ERROR;

	// request looks fine, clear bits and write back to memory
	// @cont: if children are all zero, then, propagate to parent
	for (int i = req_level; i >= 0; i--) {
#pragma HLS loop_tripcount min=1 max=LOOP_LEVEL_MAX
		ap_uint<3> width_i = (i == req_level) ? width : ap_uint<3>(1);
		ap_uint<3> idx_i = addr_to_idx(addr, i);
		if (!cont)
			break;
		if (in_cache[i]) {
			set_clear_bits(buddy_set[i].lines[nr_asso[i]], width_i, idx_i, false);
			cont = (buddy_set[i].lines[nr_asso[i]].children) == 0;

			/* when children are all zero, flush it */
			if (!buddy_set[i].lines[nr_asso[i]].children && buddy_set[i].level > 0) {
				dram_write(tag_level_to_drambuddy(dram_addr, buddy_set[i].lines[nr_asso[i]].tag, buddy_set[i].level),
						&(buddy_set[i].lines[nr_asso[i]].children), dram);
				buddy_set[i].lines[nr_asso[i]].valid = 0;
				buddy_set[i].lines[nr_asso[i]].tag = 0;
			}

		} else {
			set_clear_bits(buddy_free_set[i].line, width_i, idx_i, false);
			cont = (buddy_free_set[i].line.children) == 0;
			dram_write(tag_level_to_drambuddy(dram_addr, buddy_free_set[i].line.tag, buddy_free_set[i].level),
						&(buddy_free_set[i].line.children), dram);
			buddy_free_set[i].line.valid = 0;
		}
	}

	return SUCCESS;
}

void Buddy::flush_line(BuddyCacheSet& set, ap_uint<LEVEL_MAX> level,
		       ap_uint<BUDDY_SET_TYPE> nr_asso, char* dram)
{
#pragma HLS INLINE
	dram_write(tag_level_to_drambuddy(dram_addr, set.lines[nr_asso].tag, set.level),
					&(set.lines[nr_asso].children), dram);
	set.lines[nr_asso].valid = 0;
	set.lines[nr_asso].tag = 0;
	//set.lines[nr_asso].children = 0;
}

/*
 * @cont: (short for continue)
 * true: potentially there are still children to be flushed
 * false: there are not children to be flushed anymore
 */
bool Buddy::flush_set(BuddyCacheSet& set, ap_uint<LEVEL_MAX> level, ap_uint<3> flush_idx, char* dram)
{
	bool cont = false;
	BUDDY_CACHE_SET_FLUSH:
	for (int i = 0; i < set.size; i++) {
#pragma HLS loop_tripcount min=1 max=LOOP_LEVEL_MAX
		if (tag_to_parent_idx(set.lines[i].tag, set.level) == flush_idx) {
			flush_line(set, level, i, dram);
			cont = true;
		}
	}
	return cont;
}

void Buddy::flush_children(BuddyCacheSet& set, ap_uint<BUDDY_SET_TYPE> which, char* dram)
{
	assert(which < set.size);
	if (!set.lines[which].valid)
		return;

	bool cont;
	BuddyCacheLine flush_line = set.lines[which];
	ap_uint<3> flush_tag = tag_to_parent_idx(flush_line.tag, set.level);

	/* flush a line */
	dram_write(tag_level_to_drambuddy(dram_addr, flush_line.tag, set.level),
				&(flush_line.children), dram);

	flush_line.valid = 0;

	/* flush the children of the line */
	BUDDY_CACHE_CHILDREN_SET_FLUSH:
	for (int i = set.level + 1; i < LEVEL_MAX; i++) {
#pragma HLS loop_tripcount min=1 max=LOOP_LEVEL_MAX
		cont = flush_set(buddy_set[i], set.level, flush_tag, dram);
		if (!cont)
			break;
	}
}

/*
 * true: no flush
 * false: flush
 */
bool Buddy::choose_line(BuddyCacheSet& set, ap_uint<BUDDY_SET_TYPE>* nr_asso)
{
	bool no_flush = false;
	int i;

	/* find if this set has empty line */
	ALLOC_CHOOSE_FREE_LINE:
	for (i = 0; i < set.size; i++) {
#pragma HLS loop_tripcount min=1 max=LOOP_LEVEL_MAX
		if (!set.lines[i].valid) {
			no_flush = true;
			goto end_choose_line;
		}
	}

	/* round robin */
	i = set.rand_counter;
	set.count();

end_choose_line:
	*nr_asso = i;
	return no_flush;
}

bool Buddy::tag_in_cache(BuddyCacheSet& set, ap_uint<ORDER_MAX> tag, ap_uint<BUDDY_SET_TYPE>* nr_asso)
{
	bool ret = false;
	TAG_IN_CACHE:
	for (*nr_asso = 0; *nr_asso < set.size; (*nr_asso)++) {
#pragma HLS loop_tripcount min=1 max=LOOP_LEVEL_MAX
		ret = set.lines[*nr_asso].valid && set.lines[*nr_asso].tag == tag;
		if (ret)
			break;
	}
	return ret;
}

bool Buddy::get_valid_free_set(BuddyCacheSet& set, ap_uint<3> width, ap_uint<BUDDY_SET_TYPE>* nr_asso, ap_uint<3>* idx)
{
//#pragma HLS PIPELINE
	bool ret = false;
	GET_VALID_FREE_SET:
	for (*nr_asso = 0; *nr_asso < BUDDY_SET_SIZE; (*nr_asso)++) {
//#pragma HLS UNROLL factor=UNROLL_FACTOR
//#pragma HLS loop_tripcount min=1 max=LOOP_LEVEL_MAX
		if (*nr_asso >= set.size)
			break;

		ret = get_valid_free_line(set.lines[*nr_asso], width, idx);
		if (ret)
			break;
	}
	return ret;
}

bool Buddy::test_valid_bits(BuddyCacheLine& line, ap_uint<3> width, ap_uint<3> idx)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	ap_uint<8> mask = 0;
	switch(width) {
	case 1: mask = 0x1; break;
	case 2: mask = 0x3; break;
	case 4: mask = 0xF; break;
	default: mask = 0x0;
	}
	return line.valid && (line.children & (mask << idx));
}

/*
 * no validation check here, assume parameter passed is correct
 * @set_unset
 * true: set
 * false: unset
 */
void Buddy::set_clear_bits(BuddyCacheLine& line, ap_uint<3> width, ap_uint<3> idx, bool set_clear)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	ap_uint<8> mask = 0;
	switch(width) {
	case 1: mask = 0x1; break;
	case 2: mask = 0x3; break;
	case 4: mask = 0xF; break;
	default: mask = 0x0;
	}
	if (set_clear)
		line.children |= (mask << idx);
	else
		line.children &= ~(mask << idx);
}

bool Buddy::get_valid_free_line(BuddyCacheLine& line, ap_uint<3> width, ap_uint<3>* idx)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	if (!line.valid)
		return false;

	bool ret = true;
	ap_uint<8> mask = 0;
	switch(width) {
	case 1:
		*idx = get_free_1bit(line);
		mask = 0x1;
		break;
	case 2:
		*idx = get_free_2bit(line);
		mask = 0x3;
		break;
	case 4:
		*idx = get_free_4bit(line);
		mask = 0xF;
		break;
	default:
		ret = false;
	}
	if ((mask << (*idx)) & line.children) {
		ret = false;
	}
	return ret;
}

ap_uint<3> Buddy::get_free_4bit(BuddyCacheLine& line)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	return (line.children & 0xF) == 0 ? 0 : 4;
}

ap_uint<3> Buddy::get_free_2bit(BuddyCacheLine& line)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	if (!(line.children & 0x3))
		return 0;
	else if (!(line.children & 0xC))
		return 2;
	else if (!(line.children & 0x30))
		return 4;
	else
		return 6;
}

ap_uint<3> Buddy::get_free_1bit(BuddyCacheLine& line)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	if (!(line.children & 0x1))
		return 0;
	else if (!(line.children & 0x2))
		return 1;
	else if (!(line.children & 0x4))
		return 2;
	else if (!(line.children & 0x8))
		return 3;
	else if (!(line.children & 0x10))
		return 4;
	else if (!(line.children & 0x20))
		return 5;
	else if (!(line.children & 0x40))
		return 6;
	else
		return 7;
}

ap_uint<LEVEL_MAX> Buddy::order_to_level(ap_uint<ORDER_MAX> order)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	return ap_uint<LEVEL_MAX>((ORDER_MAX - 1 - order) / 3);
}

ap_uint<3> Buddy::order_to_width(ap_uint<ORDER_MAX> order)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	return ap_uint<3>(1 << (2 - ((ORDER_MAX - 1 - order) % 3)));
}

ap_uint<ORDER_MAX> Buddy::addr_to_tag(ap_uint<PA_SHIFT> addr, ap_uint<LEVEL_MAX> level)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	return ap_uint<ORDER_MAX>((addr(BLOCK_SHIFT - 1, BUDDY_MIN_SHIFT)) & ~(ap_uint<ORDER_MAX>(-1) >> (level * 3)));
}

ap_uint<3> Buddy::addr_to_idx(ap_uint<PA_SHIFT> addr, ap_uint<LEVEL_MAX> level)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	assert(level < LEVEL_MAX);
	/* use shift and mask */
	/* top 3 bits are 1, 0 else where */
	const ap_uint<BLOCK_SHIFT> mask = ap_uint<BLOCK_SHIFT>(-1) ^ (ap_uint<BLOCK_SHIFT>(-1) >> 3);
	ap_uint<BLOCK_SHIFT> tmp_idx = (ap_uint<BLOCK_SHIFT>(addr) << (3 * level)) & mask;
	return tmp_idx(BLOCK_SHIFT - 1, BLOCK_SHIFT - 3);
}

ap_uint<PA_SHIFT> Buddy::tag_to_addr(ap_uint<ORDER_MAX> tag)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	return ap_uint<PA_SHIFT>(tag) << BUDDY_MIN_SHIFT;
}

ap_uint<ORDER_MAX> Buddy::tag_to_ancestor_tag(ap_uint<ORDER_MAX> tag, ap_uint<LEVEL_MAX> level)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	assert(level >= 0);
	return (tag) & ~(ap_uint<ORDER_MAX>(-1) >> (level * 3));
}

ap_uint<3> Buddy::tag_to_ancestor_idx(ap_uint<ORDER_MAX> tag, ap_uint<LEVEL_MAX> level)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	assert(level >= 0 && level < LEVEL_MAX);
#if ORDER_MAX % 3 != 0
	ap_uint<ORDER_MAX_PAD> tag_pad = (tag, ap_uint<ORDER_PAD_BITS>(0));
#else
	ap_uint<ORDER_MAX_PAD> tag_pad = tag;
#endif
	/* Don't worry about the warning */
	return tag_pad(ORDER_MAX_PAD - 1 - level*3, ORDER_MAX_PAD - 3 - level*3);
}

ap_uint<3> Buddy::tag_to_parent_idx(ap_uint<ORDER_MAX> tag, ap_uint<LEVEL_MAX> level)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	assert(level > 0);
	return tag_to_ancestor_idx(tag, level - 1);
}

ap_uint<ORDER_MAX> Buddy::parenttag_idx_to_tag(ap_uint<ORDER_MAX> parent_tag,
					       ap_uint<LEVEL_MAX> parent_level, ap_uint<3> idx)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	return parent_tag | ((idx, ap_uint<ORDER_MAX-3>(0)) >> (ap_uint<ORDER_MAX>(parent_level) * 3));
}

/*
 * address calculation method
 * for the ith level, the starting address is
 * 8^0 + 8^1 + ... + 8^(i-1) = (8^i)) / 7
 */
unsigned long Buddy::tag_level_to_drambuddy(unsigned long dram_addr, ap_uint<ORDER_MAX> tag, ap_uint<LEVEL_MAX> level)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	assert(level > 0);
#if ORDER_MAX % 3 != 0
	ap_uint<ORDER_MAX_PAD> tag_pad = (tag, ap_uint<ORDER_PAD_BITS>(0));
#else
	ap_uint<ORDER_MAX_PAD> tag_pad = tag;
#endif
	return dram_addr + (unsigned long)(tag_pad >> (3 * (LEVEL_MAX - level)))
					+ (unsigned long)((1 << (3*(unsigned long)(level))) / 7);
}

void Buddy::dram_read(ap_uint<8>* dest, unsigned long src, char* dram)
{
#pragma HLS INLINE
	memcpy((void *)dest, (void *)&dram[src], 1);
}

void Buddy::dram_write(unsigned long dest, ap_uint<8>* src, char* dram)
{
#pragma HLS INLINE
	memcpy((void *)&dram[dest], (void *)src, 1);
}

void Buddy::dump_buddy_table()
{
#ifndef __SYNTHESIZE__
#if BUDDY_DEBUG_DUMP
	std::cout << "Buddy Table Dump" << std::endl;
	for (int i = 0; i < LEVEL_MAX; i++) {
		std::cout << "LEVEL: " << i << " ";
		std::cout << "SIZE: " << buddy_set[i].size << " ";
		for (int j = 0; j < buddy_set[i].size; j++) {
			std::cout << std::dec << buddy_set[i].lines[j].valid << " "
				<< std::hex << buddy_set[i].lines[j].tag << " "
				<< buddy_set[i].lines[j].children << " | ";
		}
		std::cout << std::endl;
	}
#endif
#endif
}

Buddy::~Buddy()
{
}

void BuddyCacheSet::count()
{
	this->rand_counter++;
	if (this->rand_counter >= size)
		this->rand_counter = 0;
}
