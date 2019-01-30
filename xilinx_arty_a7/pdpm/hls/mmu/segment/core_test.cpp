#include "ap_axi_sdata.h"
#include "ap_int.h"
#include "hls_stream.h"
#include "core.hpp"

using namespace hls;

#define N 20

void translate_segment(trans_meta_axis_t *in_va, trans_meta_axis_t *out_pa);

int main(void)
{
	trans_meta_axis_t in("in"), out("out");
	trans_meta_t tmp;
	int i;

	for (i = 0; i < N; i++) {
		tmp.addr = i;
		tmp.nr_bytes = i;
		tmp.type = 0;

		in.write(tmp);
	}
	printf("Input Done.\n");

	for (i = 0; i < N; i++) {
		translate_segment(&in, &out);
	}
	printf("Processing Done.\n");

	i = 0;
	while (!out.empty()) {
		tmp = out.read();

		printf("[%2d] addr: %#lx nr_bytes: %d type: %d\n",
			i++, tmp.addr.to_int(), tmp.nr_bytes.to_int());
	}

	return 0;
}
