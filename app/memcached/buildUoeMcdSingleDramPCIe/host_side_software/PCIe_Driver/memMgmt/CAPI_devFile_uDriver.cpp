
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
//-- Filename: test_reg.cpp
//--
//-- Description:
//--
//-- Sample driver for the Memcached demo
//-- Writes and reads to/from all relevant device registers
//--
//--opens the device file instead of talking to driver
//--------------------------------------------------------------------------------
*/


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <ctype.h>
#include <termios.h>
#include <iostream>
#include <fstream>
#include <endian.h>

#define NUM_T 32

#include "uDriver.h"

using namespace std;



struct TransferData  {
        unsigned int data[NUM_T];
} *gReadData, *gWriteData;

//read 64 bit wide reg, translate to host endianness, truncate
int uDriver::ReadReg(int offset){
    #ifndef GUI
    mtx.lock();
    #endif // GUI
    void* adr = (void*)  ((uintmax_t)memblk + offset);
	uint64_t ret=*((uint64_t *)adr);
	ret=be64toh(ret);
	//int ret = le32toh(*((uint32_t *)adr));
	#ifndef GUI
	mtx.unlock();
	#endif // GUI

	return (int)ret;
}

//expand to 64 bit, convert to big endian, write to hw
void uDriver::WriteReg(int offset, int wdata){
    mtx.lock();
    /*void* adr = (void*) ((uintmax_t)memblk + offset);
	 *((uint32_t *)adr) = htole32(wdata); */
     void* adr = (void*) ((uintmax_t)memblk + offset);
	 wdata=(uint64_t) wdata;
 	 *((uint64_t *)adr) = htobe64(wdata);
	 mtx.unlock();
}

//bulk read from beginning of device memory. Not really needed
int uDriver::WriteData(char* buff, int size)
{
//        mtx.lock();
//        int ret = write(g_devFile, buff, size);
//        mtx.unlock();
//        return (ret);
    printf("not implemented");
}

//bulk write to beginning of device memory Not really needed
int uDriver::ReadData(char *buff, int size)
{
//        mtx.lock();
//        int ret = read(g_devFile, buff, size);
//        mtx.unlock();
        printf("not implemented");
        return (-1);
}




uDriver::uDriver(char* devFileName)
{
    //ctor

   /* printf("enter path to device file:\n");
    char filename[256];
    scanf("%255s",filename);*/

    if ((g_devFile = open(devFileName, O_RDWR)) < 0) {
        printf("Can not open %s\n",devFileName);
        printf("usage: memMgmt [fltk options] /sys/bus/pci/device/.../resource0\n");
        exit(-1);
    }
    fstat(g_devFile, &sb);
    memblk = mmap(NULL,sb.st_size, PROT_WRITE|PROT_READ, MAP_SHARED, g_devFile, 0);
  if (memblk == MAP_FAILED) {
    printf("Can not mmap %s\n",devFileName);
    exit(-1);
  }



}

uDriver::~uDriver()
{
    munmap(memblk,sb.st_size);
  close(g_devFile);

}



void uDriver::WriteFree(free_regs_t which, uint32_t value){
    WriteReg(0x2000000+0x30+4*which,value);
};
bool uDriver::ReadFree(free_regs_t which, uint32_t &ret){
    ret=ReadReg(0x2000000+0x30+4*which);
    return 0x80000000&ret;
};

bool uDriver::ReadDel(uint32_t &ret){
    ret=ReadReg(0x2000000+0x20);
    return 0x80000000&ret;
};


uint32_t uDriver::ReadStats_precise(stats_reg_t which){
    //return ReadReg(0x00+4*which);
    return ReadReg(0x2000000+0x00+0x10*which);
};
double uDriver::ReadStats_percent(stats_reg_t which){
    uint32_t maxval=(1<<22)-1;
    //printf("maxval   %x/n",maxval);
    uint32_t exact_val = ReadStats_precise(which);



    return ((double)exact_val)/maxval*100;


};

bool uDriver::isFlushReq(){
    uint32_t ret=ReadReg(0x2000000+0x40);
    return ret==1;
};
void uDriver::sendFlushAck(){
    WriteReg(0x2000000+0x44,0x1);
};
bool uDriver::isFlushDone(){
    uint32_t ret=ReadReg(0x2000000+0x48);
    return ret==1;
};

uint32_t uDriver::ReadRev(){
    return ReadReg(0x2000000+0x100);
    //return ReadReg(0xf0);
};

void uDriver::softwareControlledReset(){
    //not implemented
};
