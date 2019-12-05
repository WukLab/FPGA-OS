#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "xil_printf.h"
#include "xuartlite.h"
#include "xuartlite_l.h"
#include "xuartlite_i.h"
#include "xhwicap.h"
#include "xhwicap_i.h"
#include "xhwicap_l.h"

#define printf xil_printf

XUartLite uart_lite;
XUartLite_Config *uart_lite_cfg;

XHwIcap  icap_inst;
XHwIcap_Config *icap_cfg;

static int init_devices(void)
{
	int ret;

#if 0
	ret = XUartLite_Initialize(&uart_lite, XPAR_UARTLITE_0_DEVICE_ID);
	if (ret) {
		printf("Fail to init uart lite\n\r");
		return -1;
	}
#endif

	icap_cfg = XHwIcap_LookupConfig(XPAR_HWICAP_0_DEVICE_ID);
	if (icap_cfg == NULL) {
		printf("ICAP Lookup failed\n\r");
		return -1;
	}

	ret = XHwIcap_CfgInitialize(&icap_inst, icap_cfg, icap_cfg->BaseAddress);
	if (ret) {
		printf("ICAP init failed ret=%d\n\r", ret);
		return -1;
	}

	return 0;
}

static void test_icap(void)
{
	u32 data;
	int ret;

	ret = XHwIcap_GetConfigReg(&icap_inst, XHI_IDCODE, &data);
	printf("  IDCODE -> %08x\n\r", data);
}

static int recv_pr(int nr_bytes)
{
	int i = 0, word, nr_words;
	u8 b0, b1, b2, b3;
	int ret;

	nr_words = nr_bytes / 4;
	while (i < nr_words) {
		b0 = XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR); //MSB
		b1 = XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR);
		b2 = XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR);
		b3 = XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR); //LSB

		word = ((b0 << 24) | (b1 << 16) | (b2 << 8) | (b3));
		//printf("[%10d] %x %x %x %x \n\r", i, b0, b1, b2, b3);

		ret = XHwIcap_DeviceWrite(&icap_inst, (u32 *)&word, 1);
		if (ret) {
			printf("Fail to write to ICAP\n\r");
			return -1;
		}

		i++;
	}
	printf("PR Done. Accepted bytes: %d\n\r", i*4);
	return 0;
}

int main()
{
	u8 byte;
	int ret;
	char _bitstream_size[32] = { 0 };
	int nr_size_cnt = 0;
	int bitstream_size = 0;

    init_platform();
    ret = init_devices();
    if (ret) {
    	printf("Fail to init devices.\n\r");
    	return 0;
    }

    xil_printf("Hello World\n\r");

    test_icap();

    while (1) {
    	byte = XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR);
    	switch (byte) {
    	case '1': {
    		printf("Input bitstream size and then hit Enter:\n\r");

    		memset(_bitstream_size, 0, 32);
    		nr_size_cnt = 0;

    		while (1) {
    			byte = XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR);
    			if (byte != '\r') {
    				_bitstream_size[nr_size_cnt] = byte;
    				printf("%c",byte);
    				nr_size_cnt++;
    			} else
    				break;
    		}
    		printf("\n\r");
    		printf("%s\n\r", _bitstream_size);
    		bitstream_size = atoi(_bitstream_size);
    		printf("PR Bitstream size is %d bytes\n\r", bitstream_size);
    		break;
    	}
    	case '2': {
    		if (!bitstream_size) {
    			printf("Please set bitstream size first.\n\r");
    			break;
    		}
    		printf("Now accepting PR bitstreams.. DO NOT PRESS ANYTHING!!!..\n\r");

    		recv_pr(bitstream_size);
    		bitstream_size = 0;
    		break;
    	}
    	default:
    		printf("%c\n\r",byte);
    		break;
    	}
    }

    cleanup_platform();
    return 0;
}
