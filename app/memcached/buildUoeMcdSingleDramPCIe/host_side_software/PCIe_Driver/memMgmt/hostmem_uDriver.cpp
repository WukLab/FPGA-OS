
/*
-- (c) Copyright 2014 Xilinx, Inc. All rights reserved.
    --
    -- This file contains confidential and proprietary information
    -- of Xilinx, Inc. and is protected under U.S. and
    -- international copyright and other intellectual property
    -- laws.
    --
    -- DISCLAIMER
    -- This disclaimer is not a license and does not grant any
    -- rights to the materials distributed herewith. Except as
    -- otherwise provided in a valid license issued to you by
    -- Xilinx, and to the maximum extent permitted by applicable
    -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
    -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
    -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
    -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
    -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
    -- (2) Xilinx shall not be liable (whether in contract or tort,
    -- including negligence, or under any other theory of
    -- liability) for any loss or damage of any kind or nature
    -- related to, arising under or in connection with these
    -- materials, including for any direct, or any indirect,
    -- special, incidental, or consequential loss or damage
    -- (including loss of data, profits, goodwill, or any type of
    -- loss or damage suffered as a result of any action brought
    -- by a third party) even if such damage or loss was
    -- reasonably foreseeable or Xilinx had been advised of the
    -- possibility of the same.
    --
    -- CRITICAL APPLICATIONS
    -- Xilinx products are not designed or intended to be fail-
    -- safe, or for use in any application requiring fail-safe
    -- performance, such as life-support or safety devices or
    -- systems, Class III medical devices, nuclear facilities,
    -- applications related to the deployment of airbags, or any
    -- other applications that could lead to death, personal
    -- injury, or severe property or environmental damage
    -- (individually and collectively, "Critical
    -- Applications"). Customer assumes the sole risk and
    -- liability of any use of Xilinx products in Critical
    -- Applications, subject only to applicable laws and
    -- regulations governing limitations on product liability.
    --
    -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
    -- PART OF THIS FILE AT ALL TIMES.
//--------------------------------------------------------------------------------
//--
//-- Description:
//--
//-- driver for the Memcached demo
//-- Writes and reads to/from all relevant device registers
//--
//-- works with the "handsoff" driver.
//-- Necessary when using value store in host memory.
//--------------------------------------------------------------------------------
*/

#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <termios.h>
#include <fcntl.h>
#include <errno.h>

#include <stdint.h>
#include "handsoffdma.h"

#define NUM_T 32


#include "uDriver.h"


using namespace std;

struct TransferData  {

        unsigned int data[NUM_T];

} *gReadData, *gWriteData;


int uDriver::ReadReg(int offset){
    mtx.lock();//I own q now
	xpcie_arg_t* q=(xpcie_arg_t*) argpt;
	(*q).offset=offset;
	(*q).rdata=0x55;//will be overwritten, is just a sanity check
	(*q).wdata=0x66;//not used for read,   is just a sanity check

	int ret=ioctl(g_devFile,HANDSOFF_READ_DEV,q);//XPCIE_READ_REG is a constant defined in xpcie.h
	uint32_t rdata=(*q).rdata;

	mtx.unlock();//I don't own q any more
	if(ret){
		printf("error while reading pcie. offset:%x  error:%x\n",offset,ret);
	}
	//printf("got back offs=%x   rdata=%x    wdata=%x    rcode %d\n",(*q).offset,(*q).rdata,(*q).wdata,ret);
	return (rdata);
}

void uDriver::WriteReg(int offset, int wdata){

    mtx.lock();//I own q now
	xpcie_arg_t* q=(xpcie_arg_t*) argpt;
	(*q).offset=offset;
	(*q).rdata=0x55;//not used for write,  is just a sanity check
	(*q).wdata=wdata;
	int ret=ioctl(g_devFile,HANDSOFF_WRITE_DEV,q);
	//could now also read return value in q
	mtx.unlock();//I don't own q any more
	if(ret){
		printf("error while writing pcie. offset:%x  error:%x\n",offset,ret);
	}
	//printf("got back offs=%x   rdata=%x    wdata=%x    rcode %d\n",(*q).offset,(*q).rdata,(*q).wdata,ret);
}

//bulk read from beginning of device memory. Not really needed
int uDriver::WriteData(char* buff, int size)
{
        mtx.lock();
        int ret = write(g_devFile, buff, size);
        mtx.unlock();
        return (ret);
}

//bulk write to beginning of device memory Not really needed
int uDriver::ReadData(char *buff, int size)
{
        mtx.lock();
        int ret = read(g_devFile, buff, size);
        mtx.unlock();

        return (ret);
}




uDriver::uDriver(char* devFileName)
{
    //ctor
    g_devFile=-1;
    char devname[]="/dev/handsoffdma";
    char* devfilename=devname;
    g_devFile=open(devfilename,O_RDWR);
    if(g_devFile<0){
        printf("Error opening device file\n");
    }
    argpt= malloc(sizeof(xpcie_arg_t));


}

uDriver::~uDriver()
{
    //dtor
    free(argpt);
}



void uDriver::WriteFree(free_regs_t which, uint32_t value){
    WriteReg(0x30+4*which,value);
};
bool uDriver::ReadFree(free_regs_t which, uint32_t &ret){
    ret=ReadReg(0x30+4*which);
    return 0x80000000&ret;
};

bool uDriver::ReadDel(uint32_t &ret){
    ret=ReadReg(0x20);
    return 0x80000000&ret;
};

uint32_t uDriver::ReadStats_precise(stats_reg_t which){
    return ReadReg(0x00+4*which);
};
double uDriver::ReadStats_percent(stats_reg_t which){
    uint32_t maxval=(1<<22)-1;
    //printf("maxval   %x/n",maxval);
    uint32_t exact_val=ReadStats_precise(which);
    return (double)exact_val/maxval*100;
};

bool uDriver::isFlushReq(){
    uint32_t ret=ReadReg(0xe0);
    //old versions of hw don't have flush registers, will return -1
    //checking for value +1 ensures this software sees old hardware as
    //"never flushing" instead of "constantly flushing"

    return ret==1;
};
void uDriver::sendFlushAck(){
    WriteReg(0xe4,0x1);
};
bool uDriver::isFlushDone(){
    uint32_t ret=ReadReg(0xe8);
    return ret==1;
};

void uDriver::softwareControlledReset(){
    WriteReg(0x10,0x1);
}


uint32_t uDriver::ReadRev(){
    return ReadReg(0xf0);
};
