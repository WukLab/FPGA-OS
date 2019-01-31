#include "ap_axi_sdata.h"
#include "ap_int.h"
#include "hls_stream.h"
#include "segment.hpp"

using namespace hls;

#define N 20

void translate_segment(axis_va_t *in_va, axis_pa_t *out_pa);

int main(void)
{
	axis_va_t axis_va;
	axis_pa_t axis_pa;
	va_t va;
	pa_t pa;
	int i;

	for (i = 0; i < N; i++) {
		va.address = i;
		va.nr_bytes = i;
		va.type = 0;

		axis_va.write(va);
	}
	printf("Input Done.\n");

	for (i = 0; i < N; i++) {
		translate_segment(&axis_va, &axis_pa);
	}
	printf("Processing Done.\n");

	i = 0;
	while (!axis_pa.empty()) {
		pa = axis_pa.read();

		printf("[%2d] addr: %#lx nr_bytes: %d type: %d\n",
			i++, pa.address.to_int(), pa.nr_bytes.to_int(),
			pa.type.to_int());
	}

	return 0;
}
