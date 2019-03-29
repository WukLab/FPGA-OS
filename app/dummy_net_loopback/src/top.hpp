#ifndef _DUMMY_NET_LP_H_
#define _DUMMY_NET_LP_H_

/* Consistent with lp_stats */
#define NR_MAX_UNITS		(4)
#define NR_TESTS_PER_LEN	(1)

struct lp_stats {
	unsigned long nr_1;
	unsigned long nr_cycles_1;

	unsigned long nr_2;
	unsigned long nr_cycles_2;

	unsigned long nr_3;
	unsigned long nr_cycles_3;

	unsigned long nr_4;
	unsigned long nr_cycles_4;

#if 0
	unsigned long nr_5;
	unsigned long nr_cycles_5;

	unsigned long nr_6;
	unsigned long nr_cycles_6;

	unsigned long nr_7;
	unsigned long nr_cycles_7;

	unsigned long nr_8;
	unsigned long nr_cycles_8;
#endif
};

#endif /* _DUMMY_NET_LP_H_ */
