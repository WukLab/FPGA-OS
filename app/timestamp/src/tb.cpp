#include <stdio.h>

void global_timestamp(unsigned long *tsc);

#define N 100

int main(void)
{
	int i;
	unsigned long tsc = 0;;

	for (i = 0; i < N; i++) {
		global_timestamp(&tsc);
		printf("tsc: %llu\n", tsc);
	}
}
