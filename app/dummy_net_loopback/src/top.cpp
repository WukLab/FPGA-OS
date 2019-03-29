/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/* System-level headers */

#include <fpga/axis_net.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>
#include <string.h>

#include "top.hpp"

using namespace hls;

#define DST_APP_ID	(0)
#define MY_APP_ID	(0)

static struct lp_stats cached_stats = {0};

static inline void update_stat(int i, unsigned long start, unsigned long end,
				volatile struct lp_stats *stats)
{
#pragma HLS INLINE
	unsigned long diff = end - start;
	switch (i) {
	case 1:
		cached_stats.nr_1 ++;
		stats->nr_1 = cached_stats.nr_1;

		cached_stats.nr_cycles_1 += diff;
		stats->nr_cycles_1 = cached_stats.nr_cycles_1;
		break;
	case 2:
		cached_stats.nr_2 ++;
		stats->nr_2 = cached_stats.nr_2;

		cached_stats.nr_cycles_2 += diff;
		stats->nr_cycles_2 = cached_stats.nr_cycles_2;
		break;
	case 3:
		cached_stats.nr_3 ++;
		stats->nr_3 = cached_stats.nr_3;

		cached_stats.nr_cycles_3 += diff;
		stats->nr_cycles_3 = cached_stats.nr_cycles_3;
		break;
	case 4:
		cached_stats.nr_4 ++;
		stats->nr_4 = cached_stats.nr_4;

		cached_stats.nr_cycles_4 += diff;
		stats->nr_cycles_4 = cached_stats.nr_cycles_4;
		break;
	default:
		break;
	}
}

void net_loopback(hls::stream<struct net_axis_512> *from_net,
		  hls::stream<struct net_axis_512> *to_net,
		  volatile unsigned long *tsc,
		  volatile struct lp_stats *stats,
		  bool has_eth_lego_header,
		  ap_uint<512> *dram)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_hs port=return

#pragma HLS INTERFACE axis both port=from_net
#pragma HLS INTERFACE axis both port=to_net
#pragma HLS INTERFACE ap_none port=tsc
#pragma HLS INTERFACE ap_none port=stats
#pragma HLS INTERFACE m_axi depth=64 port=dram offset=off

	static struct net_axis_512 current;
	int i, j, k;
	static bool tested = false;
	unsigned long start_tsc, end_tsc;
	bool first_unit;

	if (tested == true)
		return;

	for (i = 1; i <= NR_MAX_UNITS; i++) {
		for (j = 0; j < NR_TESTS_PER_LEN; j++) {
			first_unit = true;

			/* Send out one packet */
			start_tsc = *tsc;
			for (k = 0; k < i; k++) {
				current.data = k + 0x101;
				current.data(511, 504) = k + 0x101;
				set_app_id(&current, DST_APP_ID);
				current.user = 0;
				current.keep = 0xffffffffffffffff;
				if (k == (i - 1))
					current.last = 1;
				else
					current.last = 0;

				to_net->write(current);
			}

			while (1) {
				if (from_net->empty())
					continue;

				current = from_net->read();
				if (first_unit) {
					end_tsc = *tsc;
					first_unit = false;
				}
				if (current.last == 1)
					break;
			}

			update_stat(i, start_tsc, end_tsc, stats);
		}
	}
	tested = true;
}
